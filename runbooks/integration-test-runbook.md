# Integration Test Runbook

## 1) Purpose
- execute repeatable integration testing for SCM_RFT before merge/cutover
- produce evidence logs for gate pass/fail decisions

## 2) Scope
- gates: `build`, `unit-integration-test`, `contract-test`, `lint-static-analysis`, `security-scan`, `smoke-test`, `migration-dry-run`
- gateway auth/member smoke
- full P0 gateway E2E (`F01~F07`)

## 3) Prerequisites
- repository root: `C:\Users\CMN-091\projects\SCM_RFT`
- Docker Desktop running
- staging infra up:
  - `powershell -ExecutionPolicy Bypass -File .\scripts\staging-up.ps1`
- auth/member/gateway started and health `UP`
- `.env.staging` present

## 4) Evidence Directory
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
$RunId = "IT-" + (Get-Date -Format "yyyyMMdd-HHmmss")
$EvDir = ".\runbooks\evidence\$RunId"
New-Item -ItemType Directory -Force $EvDir | Out-Null
Write-Host "EvidenceDir=$EvDir"
```

## 5) Standard Integration Gate Run (7 gates)
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
$RunId = "IT-" + (Get-Date -Format "yyyyMMdd-HHmmss")
$EvDir = ".\runbooks\evidence\$RunId"
New-Item -ItemType Directory -Force $EvDir | Out-Null

powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate build 2>&1 | Tee-Object "$EvDir\gate-build.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate unit-integration-test 2>&1 | Tee-Object "$EvDir\gate-unit-integration-test.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate contract-test 2>&1 | Tee-Object "$EvDir\gate-contract-test.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate lint-static-analysis 2>&1 | Tee-Object "$EvDir\gate-lint-static-analysis.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate security-scan 2>&1 | Tee-Object "$EvDir\gate-security-scan.log"

$env:SCM_ENABLE_GATEWAY_E2E_SMOKE="1"
$env:SCM_SQL_CONTAINER_NAME="scm-stg-sqlserver"
$env:SCM_ENV_FILE=".env.staging"
$env:SCM_DB_NAME="MES_HI"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate smoke-test 2>&1 | Tee-Object "$EvDir\gate-smoke-test.log"

powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate migration-dry-run 2>&1 | Tee-Object "$EvDir\gate-migration-dry-run.log"
```

## 6) Full P0 E2E Run
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
$RunId = "IT-P0-" + (Get-Date -Format "yyyyMMdd-HHmmss")
$EvDir = ".\runbooks\evidence\$RunId"
New-Item -ItemType Directory -Force $EvDir | Out-Null

powershell -ExecutionPolicy Bypass -File .\scripts\smoke-gateway-p0-e2e.ps1 `
  -SqlContainerName "scm-stg-sqlserver" `
  -EnvFile ".env.staging" `
  -Database "MES_HI" 2>&1 | Tee-Object "$EvDir\smoke-gateway-p0-e2e.log"
```

## 7) Pass Criteria
- all 7 gate commands exit code `0`
- log scan:
  - `[FAIL]` count = `0`
  - `[SKIP]` count = `0`
- smoke-test includes:
  - login/verify/member search/member by id pass
- P0 E2E includes:
  - `P0-F01~F07 gateway E2E smoke passed.`
- migration dry-run:
  - validation report exists
  - `All validation checks passed.`

## 8) Quick Log Validation
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
$EvDir = ".\runbooks\evidence\<RunId>"
rg -n "\[FAIL\]|\[SKIP\]" $EvDir -S
if ($LASTEXITCODE -eq 1) { Write-Host "NO_FAIL_SKIP" }
```

## 9) Known Failure and Immediate Fix
- symptom: smoke-test fails with `SQL container 'scm-sqlserver' is not running`
- cause: default smoke container points to dev name while current run uses staging stack
- fix: set before smoke gate
  - `SCM_SQL_CONTAINER_NAME=scm-stg-sqlserver`
  - `SCM_ENV_FILE=.env.staging`
  - `SCM_DB_NAME=MES_HI`

## 10) Required Artifacts for PR
- `gate-build.log`
- `gate-unit-integration-test.log`
- `gate-contract-test.log`
- `gate-lint-static-analysis.log`
- `gate-security-scan.log`
- `gate-smoke-test.log`
- `gate-migration-dry-run.log`
- `smoke-gateway-p0-e2e.log` (for full domain E2E PRs)
