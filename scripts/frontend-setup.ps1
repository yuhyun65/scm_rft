param(
  [switch]$Install
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$frontendRoot = Join-Path $repoRoot "frontend"
$lockPath = Join-Path $repoRoot "toolchain.lock.json"

if (-not (Test-Path $frontendRoot)) {
  throw "frontend workspace not found: $frontendRoot"
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  throw "node not found. install Node 22 first."
}

$nodeVersion = (& node -v)
Write-Host "Node detected: $nodeVersion"

if (-not (Get-Command corepack -ErrorAction SilentlyContinue)) {
  throw "corepack not found. use Node 22 distribution that includes corepack."
}

$lock = $null
if (Test-Path $lockPath) {
  $lock = Get-Content -Raw -Encoding UTF8 $lockPath | ConvertFrom-Json
}

if ($lock -and -not [string]::IsNullOrWhiteSpace([string]$lock.pnpm)) {
  & corepack prepare ("pnpm@{0}" -f [string]$lock.pnpm) --activate
  if ($LASTEXITCODE -ne 0) {
    throw "corepack prepare pnpm failed."
  }
}

& corepack pnpm -C $frontendRoot --version
if ($LASTEXITCODE -ne 0) {
  throw "pnpm version check failed."
}

if ($Install) {
  $lockFile = Join-Path $frontendRoot "pnpm-lock.yaml"
  if (Test-Path $lockFile) {
    & corepack pnpm -C $frontendRoot install --frozen-lockfile
  }
  else {
    & corepack pnpm -C $frontendRoot install
  }
  if ($LASTEXITCODE -ne 0) {
    throw "frontend dependency install failed."
  }
}

Write-Host "[OK] frontend setup ready."
