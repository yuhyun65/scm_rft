param(
  [switch]$InstallFrontend,
  [switch]$NoExit
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$toolchainScript = Join-Path $PSScriptRoot "use-toolchain.ps1"
$frontendSetupScript = Join-Path $PSScriptRoot "frontend-setup.ps1"

if (-not (Test-Path $toolchainScript)) {
  throw "toolchain script not found: $toolchainScript"
}

Set-Location $repoRoot
& $toolchainScript
if ($LASTEXITCODE -ne 0) {
  throw "toolchain bootstrap failed."
}
$env:SCM_TOOLCHAIN_READY = "1"

if ($InstallFrontend) {
  if (-not (Test-Path $frontendSetupScript)) {
    throw "frontend setup script not found: $frontendSetupScript"
  }
  & $frontendSetupScript -Install
  if ($LASTEXITCODE -ne 0) {
    throw "frontend setup failed."
  }
}

Write-Host "[OK] SCM_RFT dev shell is aligned to toolchain lock."
Write-Host "[INFO] Current directory: $repoRoot"
Write-Host "[INFO] Next: powershell -ExecutionPolicy Bypass -File .\\scripts\\ci-run-gate.ps1 -Gate frontend-build"

if ($NoExit) {
  & powershell -NoExit -Command "Set-Location '$repoRoot'; `$env:SCM_TOOLCHAIN_READY='1'; Write-Host '[INFO] Interactive shell ready (SCM_TOOLCHAIN_READY=1).'"
}
