param(
  [switch]$Install
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$frontendRoot = Join-Path $repoRoot "frontend"
$setupScript = Join-Path $PSScriptRoot "frontend-setup.ps1"

& powershell -ExecutionPolicy Bypass -File $setupScript -Install:$Install
if ($LASTEXITCODE -ne 0) {
  throw "frontend setup failed."
}

& corepack pnpm -C $frontendRoot --filter @scm-rft/web-portal dev
if ($LASTEXITCODE -ne 0) {
  throw "frontend dev server failed."
}
