param(
  [switch]$Install
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$frontendRoot = Join-Path $repoRoot "frontend"
$setupScript = Join-Path $PSScriptRoot "frontend-setup.ps1"
$toolchainScript = Join-Path $PSScriptRoot "use-toolchain.ps1"

if ($env:SCM_TOOLCHAIN_READY -ne "1") {
  if (-not (Test-Path $toolchainScript)) {
    throw "toolchain script not found: $toolchainScript"
  }
  & $toolchainScript
  if ($LASTEXITCODE -ne 0) {
    throw "toolchain bootstrap failed."
  }
  $env:SCM_TOOLCHAIN_READY = "1"
}

$setupArgs = @(
  "-ExecutionPolicy", "Bypass",
  "-File", $setupScript
)
if ($Install) {
  $setupArgs += "-Install"
}

& powershell @setupArgs
if ($LASTEXITCODE -ne 0) {
  throw "frontend setup failed."
}

& corepack pnpm -C $frontendRoot --filter @scm-rft/web-portal dev
if ($LASTEXITCODE -ne 0) {
  throw "frontend dev server failed."
}
