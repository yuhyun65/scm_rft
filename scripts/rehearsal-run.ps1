param(
  [switch]$SkipStagingUp,
  [switch]$SkipBackup,
  [switch]$FailOnMismatch
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")

Push-Location $root
try {
  if (-not $SkipStagingUp) {
    & powershell -ExecutionPolicy Bypass -File ".\scripts\staging-up.ps1"
    if ($LASTEXITCODE -ne 0) { throw "staging-up failed" }
  }

  if (-not $SkipBackup) {
    & powershell -ExecutionPolicy Bypass -File ".\scripts\backup-db.ps1" -Database "MES_HI" -Staging
    if ($LASTEXITCODE -ne 0) { throw "staging backup failed" }
  }

  if ($FailOnMismatch) {
    & powershell -ExecutionPolicy Bypass -File ".\migration\scripts\dry-run.ps1" -FailOnMismatch
  }
  else {
    & powershell -ExecutionPolicy Bypass -File ".\migration\scripts\dry-run.ps1"
  }
  if ($LASTEXITCODE -ne 0) { throw "migration dry-run failed" }

  if ($FailOnMismatch) {
    & powershell -ExecutionPolicy Bypass -File ".\migration\verify\validate-migration.ps1" -FailOnMismatch
  }
  else {
    & powershell -ExecutionPolicy Bypass -File ".\migration\verify\validate-migration.ps1"
  }
  if ($LASTEXITCODE -ne 0) { throw "migration validation failed" }

  Write-Host "[OK] Big-Bang rehearsal sequence completed."
}
finally {
  Pop-Location
}
