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

if (-not $SkipExecution) {
  $rehearsalScript = Join-Path $repoRoot "scripts/rehearsal-run.ps1"
  if (-not (Test-Path $rehearsalScript)) {
    throw "Missing script: $rehearsalScript"
  }

  $rehearsalLog = Join-Path $evDir "rehearsal-run.log"
  $rehearsalExit = Invoke-LoggedPowerShell -ArgumentLine ("-ExecutionPolicy Bypass -File `"{0}`" -FailOnMismatch" -f $rehearsalScript) -LogPath $rehearsalLog
  if ($rehearsalExit -ne 0) {
    throw "rehearsal-run failed."
  }

  foreach ($gate in $gateList) {
    $logPath = Join-Path $evDir ("gate-{0}.log" -f $gate)
    if ($gate -eq "smoke-test") {
      $env:SCM_ENABLE_GATEWAY_E2E_SMOKE = "1"
      if (-not $env:SCM_SQL_CONTAINER_NAME) {
        $env:SCM_SQL_CONTAINER_NAME = "scm-stg-sqlserver"
      }
      if (-not $env:SCM_ENV_FILE) {
        $env:SCM_ENV_FILE = ".env.staging"
      }
      if (-not $env:SCM_DB_NAME) {
        $env:SCM_DB_NAME = "MES_HI"
      }
    }
    $gateScript = Join-Path $repoRoot "scripts/ci-run-gate.ps1"
    $gateExit = Invoke-LoggedPowerShell -ArgumentLine ("-ExecutionPolicy Bypass -File `"{0}`" -Gate {1}" -f $gateScript, $gate) -LogPath $logPath
    $passed = ($gateExit -eq 0)
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
