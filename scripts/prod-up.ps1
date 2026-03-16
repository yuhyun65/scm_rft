param(
  [string]$RunId = "",
  [string]$EnvFile = ".env.production",
  [int]$StartupTimeoutSec = 300,
  [int]$DatabaseReadyTimeoutSec = 180,
  [int]$PollIntervalSec = 2,
  [switch]$StopExistingPorts,
  [switch]$BuildIfMissing
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
. (Join-Path $PSScriptRoot "prod-orchestration-common.ps1")

if ([string]::IsNullOrWhiteSpace($RunId)) {
  $RunId = "SCM-233-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
}

$evidenceDir = Join-Path $repoRoot ("runbooks/evidence/{0}" -f $RunId)
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null
$pidFile = Join-Path $evidenceDir "prod-service-pids.json"

$catalog = Get-ProdServiceCatalog
$envPath = Join-Path $repoRoot $EnvFile
$envMap = Parse-EnvFile -EnvFilePath $envPath
Set-ProcessEnvMap -EnvMap $envMap

function Wait-LocalSqlServerReady {
  param(
    [Parameter(Mandatory = $true)][hashtable]$EnvironmentMap,
    [Parameter(Mandatory = $true)][int]$TimeoutSec
  )

  $dbUrl = [string]$EnvironmentMap["SCM_DB_URL"]
  $saPassword = [string]$EnvironmentMap["MSSQL_SA_PASSWORD"]
  if ([string]::IsNullOrWhiteSpace($dbUrl) -or [string]::IsNullOrWhiteSpace($saPassword)) {
    return
  }

  if ($dbUrl -notmatch "jdbc:sqlserver://localhost:1433") {
    return
  }

  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    return
  }

  $running = @(docker ps --format "{{.Names}}")
  if ($LASTEXITCODE -ne 0 -or (@($running | Where-Object { $_ -eq "scm-sqlserver" }).Count -eq 0)) {
    return
  }

  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while ((Get-Date) -lt $deadline) {
    cmd /c "docker exec scm-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P ""$saPassword"" -C -Q ""SELECT 1"" >nul 2>nul"
    if ($LASTEXITCODE -eq 0) {
      Write-Host "[OK] local SQL Server readiness check passed."
      return
    }
    Start-Sleep -Seconds 2
  }

  throw "local SQL Server did not become ready within $TimeoutSec seconds."
}

Wait-LocalSqlServerReady -EnvironmentMap $envMap -TimeoutSec $DatabaseReadyTimeoutSec

if ($BuildIfMissing) {
  & (Join-Path $repoRoot "gradlew.bat") @(
    ":services:auth:bootJar",
    ":services:member:bootJar",
    ":services:file:bootJar",
    ":services:board:bootJar",
    ":services:quality-doc:bootJar",
    ":services:order-lot:bootJar",
    ":services:inventory:bootJar",
    ":services:report:bootJar",
    ":services:gateway:bootJar"
  )
  if ($LASTEXITCODE -ne 0) {
    throw "bootJar build failed."
  }
}

$states = @()
$health = @()
$started = @()
try {
  foreach ($svc in $catalog) {
    Ensure-PortFree -Port $svc.Port -AllowForceStop:$StopExistingPorts

    $jarPath = Resolve-ServiceJarPath -RepoRoot $repoRoot -ModuleName $svc.Module
    if ([string]::IsNullOrWhiteSpace($jarPath)) {
      throw "jar not found for service '$($svc.Name)'. build first or use -BuildIfMissing."
    }

    $state = Start-ServiceJar -ServiceName $svc.Name -JarPath $jarPath -Port $svc.Port -EvidenceDir $evidenceDir -LogPrefix "up"
    $started += $state
    $states += $state

    $result = Wait-ServiceHealth -ServiceName $svc.Name -HealthUri $svc.HealthUri -ProcessId $state.ProcessId -Deadline ((Get-Date).AddSeconds($StartupTimeoutSec)) -PollIntervalSec $PollIntervalSec
    $health += $result
    if ($result.Result -ne "PASS") {
      throw "startup failed: $($svc.Name) health did not become UP."
    }
  }

  # Final sweep to ensure all services are still UP after the full dependency chain is started.
  foreach ($svc in $catalog) {
    $state = $states | Where-Object { $_.Name -eq $svc.Name } | Select-Object -First 1
    $post = Wait-ServiceHealth -ServiceName $svc.Name -HealthUri $svc.HealthUri -ProcessId $state.ProcessId -Deadline ((Get-Date).AddSeconds(30)) -PollIntervalSec $PollIntervalSec
    if ($post.Result -ne "PASS") {
      throw "startup final sweep failed: $($svc.Name) is not stable."
    }
  }

  Export-PidState -PidFilePath $pidFile -ServiceStates $states

  $summary = [System.Collections.Generic.List[string]]::new()
  $summary.Add("# SCM-233 Production Startup Summary")
  $summary.Add("")
  $summary.Add("- RunId: $RunId")
  $summary.Add("- EnvFile: $EnvFile")
  $summary.Add("- GeneratedAt: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")")
  $summary.Add("- Verdict: PASS")
  $summary.Add("")
  $summary.Add("| Service | Port | PID | Health | Attempts |")
  $summary.Add("|---|---:|---:|---|---:|")
  foreach ($svc in $catalog) {
    $st = $states | Where-Object { $_.Name -eq $svc.Name } | Select-Object -First 1
    $hr = $health | Where-Object { $_.Service -eq $svc.Name } | Select-Object -First 1
    $summary.Add("| $($svc.Name) | $($svc.Port) | $($st.ProcessId) | $($hr.Result) | $($hr.Attempt) |")
  }
  $summary.Add("")
  $summary.Add("Artifacts:")
  $summary.Add("- runbooks/evidence/$RunId/prod-service-pids.json")
  $summary.Add("- runbooks/evidence/$RunId/up-*.out.log")
  $summary.Add("- runbooks/evidence/$RunId/up-*.err.log")

  $summaryPath = Join-Path $evidenceDir "prod-up-summary.md"
  $summary | Set-Content -Encoding UTF8 $summaryPath
  Write-Host "[OK] production startup completed. summary=$summaryPath"
}
catch {
  foreach ($proc in $started) {
    try {
      Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
    }
    catch {}
  }
  throw
}
