param(
  [switch]$Build
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

  if (-not (Test-Path ".env")) {
    if (Test-Path ".env.example") {
      Copy-Item ".env.example" ".env"
      Write-Host "[INFO] .env file created from .env.example"
    }
    else {
      throw ".env.example file is missing."
    }
  }

  if ($Build) {
    & docker compose up -d --build
  }
  else {
    & docker compose up -d
  }

  if ($LASTEXITCODE -ne 0) {
    throw "docker compose up failed. Check Docker Desktop status and container logs."
  }

  Write-Host ""
  Write-Host "SCM_RFT local infrastructure is up."
  Write-Host "- Grafana    : http://localhost:3000"
  Write-Host "- Prometheus : http://localhost:9090"
  Write-Host "- Loki       : http://localhost:3100"
  Write-Host "- Tempo      : http://localhost:3200"
  Write-Host "- RabbitMQ   : http://localhost:15672"
}
finally {
  Pop-Location
}
