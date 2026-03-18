[CmdletBinding()]
param(
  [string]$EnvFile = '.env.production',
  [int]$FrontendPort = 5173,
  [switch]$KeepFrontend,
  [switch]$PlanOnly
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$envPath = Join-Path $repoRoot $EnvFile

function Invoke-Step {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][scriptblock]$Action
  )

  Write-Host "[STEP] $Name"
  if ($PlanOnly) {
    Write-Host "[PLAN] skipped execution for: $Name"
    return
  }

  & $Action
}

function Invoke-DockerCompose {
  param([Parameter(Mandatory = $true)][string[]]$Arguments)

  & docker compose @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "[FAIL] docker compose failed: $($Arguments -join ' ')"
  }
}

function Restore-GatewayPolicy {
  if (-not (Test-Path $envPath)) {
    throw "[FAIL] env file not found: $envPath"
  }

  (Get-Content $envPath) -replace '^GATEWAY_POLICY_PATH=.*$', 'GATEWAY_POLICY_PATH=infra/gateway/policies/cutover-isolation.yaml' |
    Set-Content $envPath -Encoding UTF8
  Write-Host '[OK] GATEWAY_POLICY_PATH restored to cutover-isolation.yaml'
}

function Stop-FrontendByPort {
  param([int]$Port)

  $listeners = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique
  if (-not $listeners) {
    Write-Host "[OK] no listener on port $Port"
    return
  }

  foreach ($processId in $listeners) {
    Stop-Process -Id $processId -Force -ErrorAction Stop
    Write-Host ("[OK] stopped process on port {0}: PID {1}" -f $Port, $processId)
  }
}

Set-Location $repoRoot

Invoke-Step -Name 'Stop frontend listener if present' -Action {
  if (-not $KeepFrontend) {
    Stop-FrontendByPort -Port $FrontendPort
  }
  else {
    Write-Host '[OK] frontend listener preserved by request.'
  }
}

Invoke-Step -Name 'Stop actual-topology application stack' -Action {
  Invoke-DockerCompose -Arguments @('--env-file', $EnvFile, '-f', 'docker-compose.yml', '-f', 'docker-compose.actual-topology.yml', 'down')
}

Invoke-Step -Name 'Stop infra stack' -Action {
  Invoke-DockerCompose -Arguments @('--env-file', $EnvFile, '-f', 'docker-compose.yml', 'down')
}

Invoke-Step -Name 'Restore default gateway policy' -Action {
  Restore-GatewayPolicy
}

Write-Host ''
Write-Host '[DONE] Local production-like demo cleanup completed.'
