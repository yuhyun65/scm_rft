param(
  [string]$RunId = "",
  [string]$EnvFile = ".env.production",
  [int]$StartupTimeoutSec = 300,
  [int]$PollIntervalSec = 2,
  [int]$RecoveryThresholdSec = 300,
  [switch]$StopExistingPorts
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
. (Join-Path $PSScriptRoot "prod-orchestration-common.ps1")

if ([string]::IsNullOrWhiteSpace($RunId)) {
  throw "-RunId is required. use the same RunId used by prod-up."
}

$evidenceDir = Join-Path $repoRoot ("runbooks/evidence/{0}" -f $RunId)
if (-not (Test-Path $evidenceDir)) {
  throw "evidence directory not found: $evidenceDir"
}
$pidFile = Join-Path $evidenceDir "prod-service-pids.json"
$states = Import-PidState -PidFilePath $pidFile

$catalog = Get-ProdServiceCatalog
$envPath = Join-Path $repoRoot $EnvFile
$envMap = Parse-EnvFile -EnvFilePath $envPath
Set-ProcessEnvMap -EnvMap $envMap

$restartRows = @()
$newStates = @()
$overallStart = Get-Date

foreach ($svc in $catalog) {
  $svcStart = Get-Date
  $old = $states | Where-Object { $_.Name -eq $svc.Name } | Select-Object -First 1
  if ($old) {
    try {
      $oldPid = [int]$old.ProcessId
      $proc = Get-Process -Id $oldPid -ErrorAction SilentlyContinue
      if ($proc) {
        Stop-Process -Id $oldPid -Force -ErrorAction Stop
      }
    }
    catch {
      Write-Warning "failed to stop old process for $($svc.Name): $($_.Exception.Message)"
    }
  }

  Ensure-PortFree -Port $svc.Port -AllowForceStop:$StopExistingPorts
  $jarPath = Resolve-ServiceJarPath -RepoRoot $repoRoot -ModuleName $svc.Module
  if ([string]::IsNullOrWhiteSpace($jarPath)) {
    throw "jar not found for service '$($svc.Name)'."
  }

  $newState = Start-ServiceJar -ServiceName $svc.Name -JarPath $jarPath -Port $svc.Port -EvidenceDir $evidenceDir -LogPrefix "restart"
  $newStates += $newState

  $health = Wait-ServiceHealth -ServiceName $svc.Name -HealthUri $svc.HealthUri -ProcessId $newState.ProcessId -Deadline ((Get-Date).AddSeconds($StartupTimeoutSec)) -PollIntervalSec $PollIntervalSec
  $svcElapsedSec = [int]((Get-Date) - $svcStart).TotalSeconds

  $restartRows += [pscustomobject]@{
    service = $svc.Name
    old_pid = $(if ($old) { [int]$old.ProcessId } else { 0 })
    new_pid = [int]$newState.ProcessId
    result = $health.Result
    attempts = $health.Attempt
    elapsed_sec = $svcElapsedSec
    last_error = $health.LastError
  }

  if ($health.Result -ne "PASS") {
    throw "rolling restart failed on service '$($svc.Name)'"
  }
}

$postSweepFailures = @()
foreach ($svc in $catalog) {
  $state = $newStates | Where-Object { $_.Name -eq $svc.Name } | Select-Object -First 1
  $post = Wait-ServiceHealth -ServiceName $svc.Name -HealthUri $svc.HealthUri -ProcessId $state.ProcessId -Deadline ((Get-Date).AddSeconds(30)) -PollIntervalSec $PollIntervalSec
  if ($post.Result -ne "PASS") {
    $postSweepFailures += $svc.Name
  }
}

$totalRecoverySec = [int]((Get-Date) - $overallStart).TotalSeconds
Export-PidState -PidFilePath $pidFile -ServiceStates $newStates

$summary = [System.Collections.Generic.List[string]]::new()
$summary.Add("# SCM-233 Rolling Restart Summary")
$summary.Add("")
$summary.Add("- RunId: $RunId")
$summary.Add("- EnvFile: $EnvFile")
$summary.Add("- GeneratedAt: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")")
$summary.Add("- TotalRecoverySec: $totalRecoverySec")
$summary.Add("- ThresholdSec: $RecoveryThresholdSec")
$summary.Add("- Verdict: $(if ($totalRecoverySec -le $RecoveryThresholdSec) { "PASS" } else { "FAIL" })")
$summary.Add("")
$summary.Add("| Service | Old PID | New PID | Result | Attempts | Elapsed(s) | LastError |")
$summary.Add("|---|---:|---:|---|---:|---:|---|")
foreach ($row in $restartRows) {
  $err = if ([string]::IsNullOrWhiteSpace($row.last_error)) { "-" } else { ($row.last_error -replace "\|", "/") }
  $summary.Add("| $($row.service) | $($row.old_pid) | $($row.new_pid) | $($row.result) | $($row.attempts) | $($row.elapsed_sec) | $err |")
}
$summaryPath = Join-Path $evidenceDir "prod-rolling-restart-summary.md"
$summary | Set-Content -Encoding UTF8 $summaryPath

if ($postSweepFailures.Count -gt 0) {
  throw "rolling restart post-sweep failed for: $($postSweepFailures -join ', '). summary=$summaryPath"
}

if ($totalRecoverySec -gt $RecoveryThresholdSec) {
  throw "rolling restart exceeded threshold. summary=$summaryPath"
}

Write-Host "[OK] rolling restart completed. summary=$summaryPath"
