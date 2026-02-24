param(
  [switch]$RemoveVolumes
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")

Push-Location $root
try {
  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker CLI is not installed or not found in PATH."
  }

  cmd /c "docker info >nul 2>nul"
  if ($LASTEXITCODE -ne 0) {
    throw "Docker daemon is not running. Start Docker Desktop and retry."
  }

  if ($RemoveVolumes) {
    & docker compose down -v
    if ($LASTEXITCODE -ne 0) {
      throw "docker compose down -v failed."
    }
    Write-Host "[INFO] Containers stopped and volumes removed."
  }
  else {
    & docker compose down
    if ($LASTEXITCODE -ne 0) {
      throw "docker compose down failed."
    }
    Write-Host "[INFO] Containers stopped."
  }
}
finally {
  Pop-Location
}
