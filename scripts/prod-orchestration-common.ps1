Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-ProdServiceCatalog {
  return @(
    [pscustomobject]@{ Name = "auth"; Module = "auth"; Port = 8081; HealthUri = "http://localhost:8081/actuator/health" },
    [pscustomobject]@{ Name = "member"; Module = "member"; Port = 8082; HealthUri = "http://localhost:8082/actuator/health" },
    [pscustomobject]@{ Name = "file"; Module = "file"; Port = 8087; HealthUri = "http://localhost:8087/actuator/health" },
    [pscustomobject]@{ Name = "board"; Module = "board"; Port = 8083; HealthUri = "http://localhost:8083/actuator/health" },
    [pscustomobject]@{ Name = "quality-doc"; Module = "quality-doc"; Port = 8084; HealthUri = "http://localhost:8084/actuator/health" },
    [pscustomobject]@{ Name = "order-lot"; Module = "order-lot"; Port = 8085; HealthUri = "http://localhost:8085/actuator/health" },
    [pscustomobject]@{ Name = "inventory"; Module = "inventory"; Port = 8086; HealthUri = "http://localhost:8086/actuator/health" },
    [pscustomobject]@{ Name = "report"; Module = "report"; Port = 8088; HealthUri = "http://localhost:8088/actuator/health" },
    [pscustomobject]@{ Name = "gateway"; Module = "gateway"; Port = 18080; HealthUri = "http://localhost:18080/actuator/health" }
  )
}

function Parse-EnvFile {
  param(
    [Parameter(Mandatory = $true)][string]$EnvFilePath
  )

  if (-not (Test-Path $EnvFilePath)) {
    throw "env file not found: $EnvFilePath"
  }

  $map = @{}
  $lines = Get-Content -Encoding UTF8 $EnvFilePath
  foreach ($line in $lines) {
    $trimmed = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
    if ($trimmed.StartsWith("#")) { continue }
    $parts = $trimmed.Split("=", 2)
    if ($parts.Count -ne 2) { continue }
    $key = $parts[0].Trim()
    $value = $parts[1].Trim()
    $map[$key] = $value
  }
  return $map
}

function Set-ProcessEnvMap {
  param(
    [Parameter(Mandatory = $true)][hashtable]$EnvMap
  )

  foreach ($key in $EnvMap.Keys) {
    Set-Item -Path ("Env:" + $key) -Value $EnvMap[$key]
  }
}

function Resolve-ServiceJarPath {
  param(
    [Parameter(Mandatory = $true)][string]$RepoRoot,
    [Parameter(Mandatory = $true)][string]$ModuleName
  )

  $libsDir = Join-Path $RepoRoot ("services/{0}/build/libs" -f $ModuleName)
  if (-not (Test-Path $libsDir)) {
    return $null
  }

  $jar = Get-ChildItem -Path $libsDir -Filter "*.jar" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notmatch "-plain\.jar$" } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  if (-not $jar) {
    return $null
  }

  return $jar.FullName
}

function Ensure-PortFree {
  param(
    [Parameter(Mandatory = $true)][int]$Port,
    [switch]$AllowForceStop
  )

  $listeners = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
  if ($listeners.Count -eq 0) {
    return
  }

  if (-not $AllowForceStop) {
    $owners = $listeners | ForEach-Object { $_.OwningProcess } | Sort-Object -Unique
    throw "port $Port is already in use. pids=[$($owners -join ',')]"
  }

  $owners = $listeners | ForEach-Object { $_.OwningProcess } | Sort-Object -Unique
  foreach ($owner in $owners) {
    try {
      Stop-Process -Id $owner -Force -ErrorAction Stop
    }
    catch {
      Write-Warning "failed to stop pid=$owner for port $Port : $($_.Exception.Message)"
    }
  }
  Start-Sleep -Seconds 1
}

function Start-ServiceJar {
  param(
    [Parameter(Mandatory = $true)][string]$ServiceName,
    [Parameter(Mandatory = $true)][string]$JarPath,
    [Parameter(Mandatory = $true)][int]$Port,
    [Parameter(Mandatory = $true)][string]$EvidenceDir,
    [Parameter(Mandatory = $true)][string]$LogPrefix
  )

  $outLog = Join-Path $EvidenceDir ("{0}-{1}.out.log" -f $LogPrefix, $ServiceName)
  $errLog = Join-Path $EvidenceDir ("{0}-{1}.err.log" -f $LogPrefix, $ServiceName)
  if (Test-Path $outLog) { Remove-Item -Force $outLog }
  if (Test-Path $errLog) { Remove-Item -Force $errLog }

  $javaExe = "java"
  $javaHomeExe = Join-Path $env:JAVA_HOME "bin\\java.exe"
  $jdk21Fallback = Join-Path $env:USERPROFILE ".jdks\\jdk-21.0.10+7\\bin\\java.exe"
  if (-not [string]::IsNullOrWhiteSpace($env:JAVA_HOME) -and (Test-Path $javaHomeExe)) {
    $javaExe = $javaHomeExe
  }
  elseif (Test-Path $jdk21Fallback) {
    $javaExe = $jdk21Fallback
  }

  $args = @(
    "-jar", $JarPath,
    "--spring.profiles.active=prod",
    ("--server.port={0}" -f $Port)
  )

  $proc = Start-Process -FilePath $javaExe -ArgumentList $args -PassThru -WindowStyle Hidden -RedirectStandardOutput $outLog -RedirectStandardError $errLog
  return [pscustomobject]@{
    Name = $ServiceName
    Port = $Port
    ProcessId = $proc.Id
    OutLog = $outLog
    ErrLog = $errLog
    JarPath = $JarPath
  }
}

function Wait-ServiceHealth {
  param(
    [Parameter(Mandatory = $true)][string]$ServiceName,
    [Parameter(Mandatory = $true)][string]$HealthUri,
    [Parameter(Mandatory = $true)][int]$ProcessId,
    [Parameter(Mandatory = $true)][datetime]$Deadline,
    [int]$PollIntervalSec = 2
  )

  $attempt = 0
  $lastError = ""
  while ((Get-Date) -lt $Deadline) {
    $attempt += 1
    if (-not (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue)) {
      return [pscustomobject]@{
        Service = $ServiceName
        Uri = $HealthUri
        Status = "DOWN"
        Result = "FAIL"
        Attempt = $attempt
        LastError = "process exited before health UP"
      }
    }

    try {
      $resp = Invoke-RestMethod -Method Get -Uri $HealthUri -TimeoutSec 5
      $status = if ($resp.status) { "$($resp.status)".ToUpperInvariant() } else { "UNKNOWN" }
      if ($status -eq "UP") {
        return [pscustomobject]@{
          Service = $ServiceName
          Uri = $HealthUri
          Status = "UP"
          Result = "PASS"
          Attempt = $attempt
          LastError = ""
        }
      }
      $lastError = "status=$status"
    }
    catch {
      $lastError = $_.Exception.Message
    }

    Start-Sleep -Seconds $PollIntervalSec
  }

  return [pscustomobject]@{
    Service = $ServiceName
    Uri = $HealthUri
    Status = "DOWN"
    Result = "FAIL"
    Attempt = $attempt
    LastError = $lastError
  }
}

function Export-PidState {
  param(
    [Parameter(Mandatory = $true)][string]$PidFilePath,
    [Parameter(Mandatory = $true)][object[]]$ServiceStates
  )
  $ServiceStates | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $PidFilePath
}

function Import-PidState {
  param(
    [Parameter(Mandatory = $true)][string]$PidFilePath
  )

  if (-not (Test-Path $PidFilePath)) {
    throw "pid state not found: $PidFilePath"
  }

  $data = Get-Content -Raw -Encoding UTF8 $PidFilePath | ConvertFrom-Json
  if ($data -is [System.Array]) {
    return @($data)
  }
  return @($data)
}
