param(
  [string]$RunId = "",
  [switch]$SkipExecution
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

if ([string]::IsNullOrWhiteSpace($RunId)) {
  $RunId = "R1-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
}

$evDir = Join-Path $repoRoot ("runbooks/evidence/{0}" -f $RunId)
New-Item -ItemType Directory -Force -Path $evDir | Out-Null

$gateList = @(
  "build",
  "unit-integration-test",
  "contract-test",
  "smoke-test",
  "migration-dry-run"
)

$results = @()

if (-not $SkipExecution) {
  $rehearsalScript = Join-Path $repoRoot "scripts/rehearsal-run.ps1"
  if (-not (Test-Path $rehearsalScript)) {
    throw "Missing script: $rehearsalScript"
  }

  & powershell -ExecutionPolicy Bypass -File $rehearsalScript -FailOnMismatch 2>&1 | Tee-Object (Join-Path $evDir "rehearsal-run.log")
  if ($LASTEXITCODE -ne 0) {
    throw "rehearsal-run failed."
  }

  foreach ($gate in $gateList) {
    $logPath = Join-Path $evDir ("gate-{0}.log" -f $gate)
    if ($gate -eq "smoke-test") {
      $env:SCM_ENABLE_GATEWAY_E2E_SMOKE = "1"
    }
    & powershell -ExecutionPolicy Bypass -File (Join-Path $repoRoot "scripts/ci-run-gate.ps1") -Gate $gate 2>&1 | Tee-Object $logPath
    $passed = ($LASTEXITCODE -eq 0)
    $results += [pscustomobject]@{
      Gate = $gate
      Passed = $passed
      LogPath = $logPath
    }
    if (-not $passed) {
      throw ("gate failed: {0}" -f $gate)
    }
  }
}

$summaryPath = Join-Path $evDir "signoff-input.md"
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# SCM-214 Signoff Input")
[void]$sb.AppendLine("")
[void]$sb.AppendLine(("- RunId: {0}" -f $RunId))
[void]$sb.AppendLine(("- GeneratedAt: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")))
[void]$sb.AppendLine(("- EvidenceDir: {0}" -f $evDir))
[void]$sb.AppendLine(("- ExecutionMode: {0}" -f ($(if ($SkipExecution) { "SKIPPED" } else { "FULL" }))))
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Mandatory Gate Results")
[void]$sb.AppendLine("| Gate | Result | Log |")
[void]$sb.AppendLine("|---|---|---|")
if ($results.Count -eq 0) {
  foreach ($gate in $gateList) {
    [void]$sb.AppendLine(("| {0} | PENDING | runbooks/evidence/{1}/gate-{0}.log |" -f $gate, $RunId))
  }
}
else {
  foreach ($r in $results) {
    $resultText = if ($r.Passed) { "PASS" } else { "FAIL" }
    $rel = $r.LogPath.Replace(($repoRoot.Path + "\"), "")
    [void]$sb.AppendLine(("| {0} | {1} | {2} |" -f $r.Gate, $resultText, $rel))
  }
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Signoff Document")
[void]$sb.AppendLine("- Update: runbooks/go-nogo-signoff.md")
[void]$sb.AppendLine("- Required links:")
[void]$sb.AppendLine("  - runbooks/evidence/<RunId>/gate-*.log")
[void]$sb.AppendLine("  - migration/reports/validation-*.md latest")
[void]$sb.AppendLine("  - smoke log and metric snapshots")

$sb.ToString() | Set-Content -Encoding UTF8 $summaryPath
Write-Host ("[OK] Signoff input generated: {0}" -f $summaryPath)
