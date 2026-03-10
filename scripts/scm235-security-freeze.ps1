param(
  [string]$RunId = ("SCM-235-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$gateScript = Join-Path $repoRoot "scripts/ci-run-gate.ps1"
$evidenceDir = Join-Path $repoRoot ("runbooks/evidence/{0}" -f $RunId)

if (-not (Test-Path $gateScript)) {
  throw "[FAIL] missing gate script: $gateScript"
}

New-Item -ItemType Directory -Force $evidenceDir | Out-Null

function Invoke-RequiredGate {
  param([Parameter(Mandatory = $true)][string]$Gate)

  $logPath = Join-Path $evidenceDir ("gate-{0}.log" -f $Gate)
  Write-Host ("[INFO] running required gate: {0}" -f $Gate)

  & powershell -ExecutionPolicy Bypass -File $gateScript -Gate $Gate 2>&1 | Tee-Object $logPath | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "[FAIL] gate failed: $Gate"
  }

  if (Select-String -Path $logPath -SimpleMatch "[FAIL]" -Quiet) {
    throw "[FAIL] gate log contains [FAIL]: $logPath"
  }

  if (Select-String -Path $logPath -SimpleMatch "[SKIP]" -Quiet) {
    throw "[FAIL] gate log contains [SKIP]: $logPath"
  }

  return $logPath
}

$lintLog = Invoke-RequiredGate -Gate "lint-static-analysis"
$securityLog = Invoke-RequiredGate -Gate "security-scan"

$branchName = (& git -C $repoRoot branch --show-current).Trim()
$generatedAt = Get-Date

$summaryMdPath = Join-Path $evidenceDir "security-freeze-summary.md"
$summaryJsonPath = Join-Path $evidenceDir "security-freeze-summary.json"

$summaryMd = @"
# SCM-235 Security Freeze Summary

- RunId: $RunId
- Branch: $branchName
- GeneratedAt: $($generatedAt.ToString("yyyy-MM-dd HH:mm:ss zzz"))

## DoD Result

- High unresolved findings: 0
- Secret exposure patterns: 0
- Gate skip count: 0

## Gate Evidence

| Gate | Result | Evidence |
|---|---|---|
| lint-static-analysis | PASS | runbooks/evidence/$RunId/gate-lint-static-analysis.log |
| security-scan | PASS | runbooks/evidence/$RunId/gate-security-scan.log |

## Notes

- SCM-235 freeze baseline requires both gates to pass with no [FAIL] and no [SKIP] markers.
"@

$summaryMd | Set-Content -Path $summaryMdPath -Encoding UTF8

$summaryObj = [ordered]@{
  runId = $RunId
  branch = $branchName
  generatedAt = $generatedAt.ToString("o")
  dod = [ordered]@{
    highUnresolvedFindings = 0
    secretExposurePatterns = 0
    gateSkipCount = 0
  }
  gates = @(
    [ordered]@{
      name = "lint-static-analysis"
      result = "PASS"
      evidence = (Resolve-Path $lintLog).Path
    },
    [ordered]@{
      name = "security-scan"
      result = "PASS"
      evidence = (Resolve-Path $securityLog).Path
    }
  )
}

$summaryObj | ConvertTo-Json -Depth 8 | Set-Content -Path $summaryJsonPath -Encoding UTF8

Write-Host "[OK] SCM-235 security freeze complete"
Write-Host ("[OK] summary: {0}" -f $summaryMdPath)
Write-Host ("[OK] summary-json: {0}" -f $summaryJsonPath)
