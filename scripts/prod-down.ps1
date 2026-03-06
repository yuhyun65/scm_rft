param(
  [string]$RunId = "",
  [string]$PidFile = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
. (Join-Path $PSScriptRoot "prod-orchestration-common.ps1")

if ([string]::IsNullOrWhiteSpace($PidFile)) {
  if ([string]::IsNullOrWhiteSpace($RunId)) {
    throw "either -RunId or -PidFile is required."
  }
  $PidFile = Join-Path $repoRoot ("runbooks/evidence/{0}/prod-service-pids.json" -f $RunId)
}

$states = Import-PidState -PidFilePath $PidFile
$evidenceDir = Split-Path -Parent $PidFile

$rows = @()
foreach ($state in $states) {
  $processId = [int]$state.ProcessId
  $stopped = $false
  $message = ""
  try {
    $proc = Get-Process -Id $processId -ErrorAction SilentlyContinue
    if ($proc) {
      Stop-Process -Id $processId -Force -ErrorAction Stop
      $stopped = $true
      $message = "stopped"
    }
    else {
      $stopped = $true
      $message = "already not running"
    }
  }
  catch {
    $stopped = $false
    $message = $_.Exception.Message
  }

  $rows += [pscustomobject]@{
    service = "$($state.Name)"
    pid = $processId
    result = $(if ($stopped) { "PASS" } else { "FAIL" })
    message = $message
  }
}

$summary = [System.Collections.Generic.List[string]]::new()
$summary.Add("# SCM-233 Production Shutdown Summary")
$summary.Add("")
$summary.Add("- GeneratedAt: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")")
$summary.Add("- PidFile: $PidFile")
$summary.Add("")
$summary.Add("| Service | PID | Result | Message |")
$summary.Add("|---|---:|---|---|")
foreach ($r in $rows) {
  $msg = if ([string]::IsNullOrWhiteSpace($r.message)) { "-" } else { ($r.message -replace "\|", "/") }
  $summary.Add("| $($r.service) | $($r.pid) | $($r.result) | $msg |")
}

$summaryPath = Join-Path $evidenceDir "prod-down-summary.md"
$summary | Set-Content -Encoding UTF8 $summaryPath

$failCount = @($rows | Where-Object { $_.result -eq "FAIL" }).Count
if ($failCount -gt 0) {
  throw "shutdown completed with failures. summary=$summaryPath"
}

Write-Host "[OK] production shutdown completed. summary=$summaryPath"
