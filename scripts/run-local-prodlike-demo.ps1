[CmdletBinding()]
param(
  [ValidateSet('ReadOnly','FullFeature')]
  [string]$Mode = 'FullFeature',
  [switch]$LaunchFrontend,
  [switch]$PlanOnly,
  [string]$Database = 'SCM_RFT_PRODLIKE',
  [string]$SqlContainerName = 'scm-sqlserver',
  [string]$EnvFile = '.env.production',
  [int]$HealthWaitTimeoutSec = 300,
  [int]$GatewayHealthTimeoutSec = 300,
  [int]$GatewayHealthPollIntervalSec = 5
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

function Assert-PathExists {
  param([Parameter(Mandatory = $true)][string]$Path)
  if (-not (Test-Path $Path)) {
    throw "[FAIL] path not found: $Path"
  }
}

function Set-GatewayPolicyPath {
  param([Parameter(Mandatory = $true)][string]$PolicyPath)

  Assert-PathExists -Path $envPath
  (Get-Content $envPath) -replace '^GATEWAY_POLICY_PATH=.*$', "GATEWAY_POLICY_PATH=$PolicyPath" |
    Set-Content $envPath -Encoding UTF8
  Write-Host "[OK] GATEWAY_POLICY_PATH=$PolicyPath"
}

function Wait-ForGatewayHealth {
  param(
    [Parameter(Mandatory = $true)][string]$Uri,
    [int]$TimeoutSec = 180,
    [int]$PollIntervalSec = 5
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while ((Get-Date) -lt $deadline) {
    try {
      $response = Invoke-RestMethod -Uri $Uri -TimeoutSec 15
      if ($response.status -eq 'UP') {
        Write-Host "[OK] gateway health is UP: $Uri"
        return
      }
    }
    catch {
      Start-Sleep -Seconds $PollIntervalSec
      continue
    }

    Start-Sleep -Seconds $PollIntervalSec
  }

  throw "[FAIL] gateway health did not become UP within ${TimeoutSec}s: $Uri"
}

function Invoke-PowerShellScript {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [object[]]$Arguments = @()
  )

  $normalizedArgs = foreach ($arg in $Arguments) {
    if ($arg -is [bool]) {
      if ($arg) { '$true' } else { '$false' }
    }
    else {
      [string]$arg
    }
  }

  $cmd = @('-NoProfile','-ExecutionPolicy','Bypass','-File', $FilePath) + $normalizedArgs
  & powershell.exe @cmd
  if ($LASTEXITCODE -ne 0) {
    throw "[FAIL] script failed: $FilePath"
  }
}

function Invoke-DockerCompose {
  param([Parameter(Mandatory = $true)][string[]]$Arguments)

  & docker compose @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "[FAIL] docker compose failed: $($Arguments -join ' ')"
  }
}

Assert-PathExists -Path $envPath
Set-Location $repoRoot

$frontendScript = Join-Path $repoRoot 'scripts\frontend-dev.ps1'
$useToolchainScript = Join-Path $repoRoot 'scripts\use-toolchain.ps1'
$checkSecretsScript = Join-Path $repoRoot 'scripts\check-prod-secrets.ps1'
$seedDemoScript = Join-Path $repoRoot 'scripts\seed-demo-data.ps1'
$authMemberSmokeScript = Join-Path $repoRoot 'scripts\smoke-gateway-auth-member-e2e.ps1'
$p0SmokeScript = Join-Path $repoRoot 'scripts\smoke-gateway-p0-e2e.ps1'

foreach ($path in @($frontendScript, $useToolchainScript, $checkSecretsScript, $seedDemoScript, $authMemberSmokeScript, $p0SmokeScript)) {
  Assert-PathExists -Path $path
}

$phaseAPath = 'infra/gateway/policies/cutover-isolation.yaml'
$phaseBPath = 'infra/gateway/policies/post-cutover-write-open.yaml'
$summaryPath = Join-Path $repoRoot ("runbooks/evidence/LOCAL-PRODLIKE-DEMO-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + "\demo-launch-summary.md")
$summaryDir = Split-Path -Parent $summaryPath

Invoke-Step -Name 'Apply toolchain policy' -Action {
  Invoke-PowerShellScript -FilePath $useToolchainScript
}

Invoke-Step -Name 'Validate local .env.production' -Action {
  Invoke-PowerShellScript -FilePath $checkSecretsScript -Arguments @('-EnvFile', $EnvFile)
}

Invoke-Step -Name 'Set Phase A gateway policy' -Action {
  Set-GatewayPolicyPath -PolicyPath $phaseAPath
}

Invoke-Step -Name 'Verify docker daemon' -Action {
  & docker info *> $null
  if ($LASTEXITCODE -ne 0) {
    throw '[FAIL] docker daemon is not running.'
  }
  Write-Host '[OK] docker daemon is running.'
}

Invoke-Step -Name 'Start infra containers' -Action {
  Invoke-DockerCompose -Arguments @('--env-file', $EnvFile, '-f', 'docker-compose.yml', 'up', '-d', 'sqlserver', 'redis', 'rabbitmq', 'loki', 'prometheus', 'tempo', 'grafana')
}

Invoke-Step -Name 'Start actual-topology application stack' -Action {
  Invoke-DockerCompose -Arguments @('--env-file', $EnvFile, '-f', 'docker-compose.yml', '-f', 'docker-compose.actual-topology.yml', 'up', '-d')
}

Invoke-Step -Name 'Seed rich demo data' -Action {
  Invoke-PowerShellScript -FilePath $seedDemoScript -Arguments @('-Database', $Database, '-SqlContainerName', $SqlContainerName, '-EnvFile', $EnvFile)
}

Invoke-Step -Name 'Validate auth/member/gateway path' -Action {
    Invoke-PowerShellScript -FilePath $authMemberSmokeScript -Arguments @(
      '-GatewayBaseUrl', 'http://localhost:18080',
      '-AuthHealthUrl', 'http://localhost:8081/actuator/health',
      '-MemberHealthUrl', 'http://localhost:8082/actuator/health',
      '-GatewayHealthUrl', 'http://localhost:18080/actuator/health',
      '-Database', $Database,
      '-SqlContainerName', $SqlContainerName,
      '-EnvFile', $EnvFile,
      '-HealthWaitTimeoutSec', [string]$HealthWaitTimeoutSec
    )
  }

if ($Mode -eq 'FullFeature') {
  Invoke-Step -Name 'Switch gateway policy to write-open mode' -Action {
    Set-GatewayPolicyPath -PolicyPath $phaseBPath
  }

  Invoke-Step -Name 'Recreate gateway with write-open policy' -Action {
    Invoke-DockerCompose -Arguments @('--env-file', $EnvFile, '-f', 'docker-compose.yml', '-f', 'docker-compose.actual-topology.yml', 'up', '-d', 'gateway', '--force-recreate')
  }

  Invoke-Step -Name 'Wait for gateway health after policy switch' -Action {
    Wait-ForGatewayHealth -Uri 'http://localhost:18080/actuator/health' -TimeoutSec $GatewayHealthTimeoutSec -PollIntervalSec $GatewayHealthPollIntervalSec
  }

  Invoke-Step -Name 'Run full P0 smoke' -Action {
    Invoke-PowerShellScript -FilePath $p0SmokeScript -Arguments @(
      '-GatewayBaseUrl', 'http://localhost:18080',
      '-Database', $Database,
      '-SqlContainerName', $SqlContainerName,
      '-EnvFile', $EnvFile
    )
  }
}

if ($LaunchFrontend) {
  Invoke-Step -Name 'Launch frontend dev server in a separate PowerShell session' -Action {
    Start-Process powershell.exe -WorkingDirectory $repoRoot -ArgumentList @('-NoExit','-ExecutionPolicy','Bypass','-File', $frontendScript)
    Write-Host '[OK] frontend-dev.ps1 launched in a separate PowerShell window.'
  }
}

Invoke-Step -Name 'Write demo summary' -Action {
  New-Item -ItemType Directory -Force $summaryDir | Out-Null
  $summary = @"
# Local Production-Like Demo Launch Summary

- Mode: $Mode
- Frontend URL: http://localhost:5173
- Gateway URL: http://localhost:18080
- Database: $Database
- Gateway policy now set to: $(Get-Content $envPath | Select-String '^GATEWAY_POLICY_PATH=' | ForEach-Object { $_.ToString().Trim() })
- Frontend launched separately: $([bool]$LaunchFrontend)

## Demo Accounts
- smoke-user / password
- smoke-admin / password
- demo-buyer-001 / password
- demo-quality-001 / password

## Suggested Inputs
- Member keyword: demo
- Order detail ID: DEMO-ORDER-1002
- Lot detail ID: DEMO-LOT-1002-A
- Board keyword: Demo
- Quality-doc keyword: Demo
- Inventory item: ITEM-001
- Warehouse: WH-01
- File detail ID: 44444444-4444-4444-4444-000000000003
- Report job detail ID: 77777777-7777-7777-7777-000000000001

## Cleanup
- Stop frontend PowerShell session if launched.
- Run:
  - `docker compose --env-file .env.production -f docker-compose.yml -f docker-compose.actual-topology.yml down`
  - `docker compose --env-file .env.production -f docker-compose.yml down`
  - restore `GATEWAY_POLICY_PATH=infra/gateway/policies/cutover-isolation.yaml`
"@
  Set-Content -Path $summaryPath -Value $summary -Encoding UTF8
  Write-Host "[OK] summary written: $summaryPath"
}

Write-Host ''
Write-Host '[DONE] Local production-like demo environment is ready.'
Write-Host ('[DONE] Mode: {0}' -f $Mode)
Write-Host '[DONE] Frontend URL: http://localhost:5173'
Write-Host '[DONE] Gateway URL: http://localhost:18080'
if (-not $LaunchFrontend) {
  Write-Host '[NEXT] Launch frontend separately with: powershell -ExecutionPolicy Bypass -File .\scripts\frontend-dev.ps1'
}
