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

  $args = @("compose")
  if (Test-Path ".env.staging") {
    $args += @("--env-file", ".env.staging")
  }
  $args += @("-f", "docker-compose.staging.yml", "down")

  if ($RemoveVolumes) {
    $args += "-v"
  }

  & docker @args
  if ($LASTEXITCODE -ne 0) {
    throw "Staging compose down failed."
  }

  if ($RemoveVolumes) {
    Write-Host "[INFO] Staging containers stopped and volumes removed."
  }
  else {
    Write-Host "[INFO] Staging containers stopped."
  }
}
finally {
  Pop-Location
}
