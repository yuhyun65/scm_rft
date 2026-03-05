param(
  [string]$RunId = "",
  [int]$ThresholdMinutes = 20,
  [string]$EnvFile = ".env.staging",
  [string]$Database = "MES_HI",
  [string]$SqlHost = "localhost",
  [int]$SqlPort = 11433,
  [string]$RedisHost = "localhost",
  [int]$RedisPort = 16379,
  [string]$GatewayPolicyPath = "infra/gateway/policies/local-auth-member-e2e.yaml",
  [int]$StartupTimeoutSec = 180,
  [int]$PollIntervalSec = 2,
  [switch]$StopExistingPorts
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

if ([string]::IsNullOrWhiteSpace($RunId)) {
  $RunId = "SCM-228-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
}

$evidenceDir = Join-Path $repoRoot ("runbooks/evidence/{0}" -f $RunId)
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null

function Get-EnvValue {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(Mandatory = $true)][string]$Key
  )

  if (-not (Test-Path $FilePath)) {
    return $null
  }

  $line = Get-Content -Encoding UTF8 $FilePath | Where-Object { $_ -match "^\s*$Key\s*=" } | Select-Object -First 1
  if (-not $line) {
    return $null
  }

  return (($line -split "=", 2)[1]).Trim()
}

function Invoke-LoggedPowerShell {
  param(
    [Parameter(Mandatory = $true)][string]$ArgumentLine,
    [Parameter(Mandatory = $true)][string]$LogPath
  )

  $errPath = "$LogPath.err"
  if (Test-Path $LogPath) { Remove-Item -Force $LogPath }
  if (Test-Path $errPath) { Remove-Item -Force $errPath }

  $proc = Start-Process -FilePath "powershell" -ArgumentList $ArgumentLine -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput $LogPath -RedirectStandardError $errPath

  if (Test-Path $errPath) {
    $err = Get-Content -Raw -Encoding UTF8 $errPath
    if (-not [string]::IsNullOrWhiteSpace($err)) {
      Add-Content -Path $LogPath -Value $err -Encoding UTF8
    }
    Remove-Item -Force $errPath
  }

  return $proc.ExitCode
}

function Get-PortOwners {
  param(
    [int[]]$Ports
  )

  $owners = @()
  foreach ($p in $Ports) {
    $rows = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue
    foreach ($r in $rows) {
      $owners += [pscustomobject]@{
        Port = $p
        OwningProcess = $r.OwningProcess
      }
    }
  }
  return $owners
}

function Ensure-PortFree {
  param(
    [int]$Port,
    [switch]$AllowForceStop
  )

  $owners = Get-PortOwners -Ports @($Port)
  if ($owners.Count -eq 0) {
    return
  }

  if (-not $AllowForceStop) {
    $ownerText = ($owners | ForEach-Object { "port=$($_.Port),pid=$($_.OwningProcess)" }) -join "; "
    throw "port in use: $ownerText"
  }

  foreach ($o in $owners | Sort-Object OwningProcess -Unique) {
    try {
      Stop-Process -Id $o.OwningProcess -Force -ErrorAction Stop
    }
    catch {
      Write-Warning "failed to stop pid=$($o.OwningProcess) on port ${Port}: $($_.Exception.Message)"
    }
  }

  Start-Sleep -Seconds 1

  $recheck = Get-PortOwners -Ports @($Port)
  if ($recheck.Count -gt 0) {
    $ownerText = ($recheck | ForEach-Object { "port=$($_.Port),pid=$($_.OwningProcess)" }) -join "; "
    throw "port still in use after stop: $ownerText"
  }
}

function Start-ServiceBootRun {
  param(
    [Parameter(Mandatory = $true)][string]$ServiceName,
    [Parameter(Mandatory = $true)][string]$GradleTask,
    [Parameter(Mandatory = $true)][string]$DbUrl,
    [Parameter(Mandatory = $true)][string]$DbPassword,
    [Parameter(Mandatory = $true)][string]$JwtSecret,
    [string]$GatewayPolicy,
    [string]$RedisHostValue,
    [int]$RedisPortValue
  )

  $outLog = Join-Path $evidenceDir ("service-{0}.out.log" -f $ServiceName)
  $errLog = Join-Path $evidenceDir ("service-{0}.err.log" -f $ServiceName)
  if (Test-Path $outLog) { Remove-Item -Force $outLog }
  if (Test-Path $errLog) { Remove-Item -Force $errLog }

  $cmdLines = @(
    "`$env:SCM_DB_URL='$DbUrl'",
    "`$env:SCM_DB_USER='sa'",
    "`$env:SCM_DB_PASSWORD='$DbPassword'",
    "`$env:SCM_DB_DRIVER='com.microsoft.sqlserver.jdbc.SQLServerDriver'",
    "`$env:SCM_AUTH_JWT_SECRET='$JwtSecret'",
    "Set-Location '$($repoRoot.Path)'"
  )

  if ($GatewayPolicy) {
    $cmdLines += "`$env:GATEWAY_POLICY_PATH='$GatewayPolicy'"
  }
  if ($RedisHostValue) {
    $cmdLines += "`$env:SPRING_DATA_REDIS_HOST='$RedisHostValue'"
  }
  if ($RedisPortValue -gt 0) {
    $cmdLines += "`$env:SPRING_DATA_REDIS_PORT='$RedisPortValue'"
  }

  $cmdLines += ".\gradlew.bat $GradleTask"
  $cmd = $cmdLines -join "; "

  $proc = Start-Process -FilePath "powershell" -ArgumentList @("-NoProfile", "-Command", $cmd) -PassThru -WindowStyle Hidden -RedirectStandardOutput $outLog -RedirectStandardError $errLog

  return [pscustomobject]@{
    Name = $ServiceName
    Process = $proc
    OutLog = $outLog
    ErrLog = $errLog
  }
}

function Wait-HealthUp {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Uri,
    [Parameter(Mandatory = $true)][datetime]$Deadline
  )

  $attempt = 0
  $lastError = ""
  while ((Get-Date) -lt $Deadline) {
    $attempt += 1
    try {
      $resp = Invoke-RestMethod -Method Get -Uri $Uri -TimeoutSec 5
      $status = if ($resp.status) { "$($resp.status)".ToUpperInvariant() } else { "UNKNOWN" }
      if ($status -eq "UP") {
        return [pscustomobject]@{
          Name = $Name
          Uri = $Uri
          Status = $status
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
    Name = $Name
    Uri = $Uri
    Status = "DOWN"
    Result = "FAIL"
    Attempt = $attempt
    LastError = $lastError
  }
}

$started = @()
$ports = @(8081, 8082, 18080)
$envPath = Join-Path $repoRoot $EnvFile
$dbPassword = Get-EnvValue -FilePath $envPath -Key "MSSQL_SA_PASSWORD"
if ([string]::IsNullOrWhiteSpace($dbPassword)) {
  throw "MSSQL_SA_PASSWORD not found in $EnvFile"
}

$jwtSecret = Get-EnvValue -FilePath $envPath -Key "SCM_AUTH_JWT_SECRET"
if ([string]::IsNullOrWhiteSpace($jwtSecret)) {
  $jwtSecret = "scm-rft-jwt-secret-key-2026-fixed"
}

$dbUrl = "jdbc:sqlserver://{0}:{1};databaseName={2};encrypt=true;trustServerCertificate=true" -f $SqlHost, $SqlPort, $Database

try {
  foreach ($p in $ports) {
    Ensure-PortFree -Port $p -AllowForceStop:$StopExistingPorts
  }

  $rollbackExecLog = Join-Path $evidenceDir "rollback-time-exec.log"
  $rollbackScript = Join-Path $repoRoot "scripts/scm226-measure-rollback-time.ps1"
  $rollbackArgs = "-ExecutionPolicy Bypass -File `"{0}`" -RunId `"{1}`" -Staging -ThresholdMinutes {2}" -f $rollbackScript, $RunId, $ThresholdMinutes
  $rollbackExit = Invoke-LoggedPowerShell -ArgumentLine $rollbackArgs -LogPath $rollbackExecLog
  if ($rollbackExit -ne 0) {
    throw "rollback measurement failed. check $rollbackExecLog"
  }

  $started += Start-ServiceBootRun -ServiceName "auth" -GradleTask ":services:auth:bootRun" -DbUrl $dbUrl -DbPassword $dbPassword -JwtSecret $jwtSecret
  $started += Start-ServiceBootRun -ServiceName "member" -GradleTask ":services:member:bootRun" -DbUrl $dbUrl -DbPassword $dbPassword -JwtSecret $jwtSecret

  $results = @()
  $results += Wait-HealthUp -Name "auth" -Uri "http://localhost:8081/actuator/health" -Deadline ((Get-Date).AddSeconds($StartupTimeoutSec))
  $results += Wait-HealthUp -Name "member" -Uri "http://localhost:8082/actuator/health" -Deadline ((Get-Date).AddSeconds($StartupTimeoutSec))

  Ensure-PortFree -Port 18080 -AllowForceStop:$StopExistingPorts
  $started += Start-ServiceBootRun -ServiceName "gateway" -GradleTask ":services:gateway:bootRun" -DbUrl $dbUrl -DbPassword $dbPassword -JwtSecret $jwtSecret -GatewayPolicy $GatewayPolicyPath -RedisHostValue $RedisHost -RedisPortValue $RedisPort
  $results += Wait-HealthUp -Name "gateway" -Uri "http://localhost:18080/actuator/health" -Deadline ((Get-Date).AddSeconds($StartupTimeoutSec))

  $allUp = (@($results | Where-Object { $_.Result -eq "PASS" }).Count -eq 3)
  $verdict = if ($allUp) { "PASS" } else { "FAIL" }

  $pidFile = Join-Path $evidenceDir "service-pids.json"
  $pidPayload = $started | ForEach-Object {
    [pscustomobject]@{
      name = $_.Name
      pid = $_.Process.Id
      outLog = $_.OutLog
      errLog = $_.ErrLog
    }
  }
  $pidPayload | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 $pidFile

  $summaryJson = Join-Path $evidenceDir "rollback-health-summary.json"
  $summaryMd = Join-Path $evidenceDir "rollback-health-summary.md"
  $payload = [pscustomobject]@{
    runId = $RunId
    generatedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    startupTimeoutSec = $StartupTimeoutSec
    allUp = $allUp
    verdict = $verdict
    rollbackSummary = "runbooks/evidence/$RunId/rollback-time-summary.md"
    services = $pidPayload
    health = $results
  }
  $payload | ConvertTo-Json -Depth 7 | Set-Content -Encoding UTF8 $summaryJson

  $md = @()
  $md += "# SCM-228 Rollback Health Summary"
  $md += ""
  $md += "- RunId: $RunId"
  $md += "- GeneratedAt: $($payload.generatedAt)"
  $md += "- StartupTimeoutSec: $StartupTimeoutSec"
  $md += "- Verdict: $verdict"
  $md += ""
  $md += "## DoD"
  $md += "| Check | Result |"
  $md += "|---|---|"
  $md += ("| rollback time <= {0} min | PASS (see rollback-time-summary.md) |" -f $ThresholdMinutes)
  $md += ("| auth/member/gateway health all UP | {0} |" -f $(if ($allUp) { "PASS" } else { "FAIL" }))
  $md += ""
  $md += "## Health"
  $md += "| Service | Uri | Status | Result | Attempts | LastError |"
  $md += "|---|---|---|---|---:|---|"
  foreach ($r in $results) {
    $err = if ([string]::IsNullOrWhiteSpace($r.LastError)) { "-" } else { ($r.LastError -replace "\|", "/") }
    $md += ("| {0} | {1} | {2} | {3} | {4} | {5} |" -f $r.Name, $r.Uri, $r.Status, $r.Result, $r.Attempt, $err)
  }
  $md += ""
  $md += "## Evidence"
  $md += "- rollback time: runbooks/evidence/$RunId/rollback-time-summary.md"
  $md += "- rollback health: runbooks/evidence/$RunId/rollback-health-summary.md"
  $md += "- rollback health json: runbooks/evidence/$RunId/rollback-health-summary.json"
  $md += "- service pids: runbooks/evidence/$RunId/service-pids.json"
  $md += "- service logs:"
  $md += "  - runbooks/evidence/$RunId/service-auth.out.log"
  $md += "  - runbooks/evidence/$RunId/service-member.out.log"
  $md += "  - runbooks/evidence/$RunId/service-gateway.out.log"
  $md -join [Environment]::NewLine | Set-Content -Encoding UTF8 $summaryMd

  Write-Host "[OK] rollback health summary generated: $summaryMd"
  if (-not $allUp) {
    throw "health verification failed. check $summaryMd"
  }
}
finally {
  foreach ($s in $started) {
    try {
      if ($s.Process -and -not $s.Process.HasExited) {
        Stop-Process -Id $s.Process.Id -Force -ErrorAction Stop
      }
    }
    catch {
      Write-Warning "failed to stop service process $($s.Name): $($_.Exception.Message)"
    }
  }
}
