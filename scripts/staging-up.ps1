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

  if (-not (Test-Path ".env.staging")) {
    if (Test-Path ".env.staging.example") {
      Copy-Item ".env.staging.example" ".env.staging"
      Write-Host "[INFO] .env.staging file created from .env.staging.example"
    }
    else {
      throw ".env.staging.example file is missing."
    }
  }

  $args = @(
    "compose",
    "--env-file", ".env.staging",
    "-f", "docker-compose.staging.yml",
    "up", "-d"
  )

  if ($Build) {
    $args += "--build"
  }

  & docker @args
  if ($LASTEXITCODE -ne 0) {
    throw "Staging compose up failed."
  }

  Write-Host ""
  Write-Host "SCM_RFT staging rehearsal environment is up."
  Write-Host "- Grafana    : http://localhost:13000"
  Write-Host "- Prometheus : http://localhost:19090"
  Write-Host "- Loki       : http://localhost:13100"
  Write-Host "- Tempo      : http://localhost:13200"
  Write-Host "- RabbitMQ   : amqp://localhost:25673 / http://localhost:35672"
  Write-Host "- SQL Server : localhost,11433"
}
finally {
  Pop-Location
}
