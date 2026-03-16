# Actual Cutover Topology Rehearsal Runbook

## Scope
- Goal: validate actual cutover topology with a 2-phase gateway policy switch.
- Baseline branch: `feature/to-be-dev-env-bootstrap`
- Baseline SHA: `6d5c3dc`
- Phase A policy: `infra/gateway/policies/cutover-isolation.yaml`
- Phase B policy: `infra/gateway/policies/post-cutover-write-open.yaml`
- Recommended topology: container-network name resolution

## 1) Execution Checklist

### A. Baseline / Policy
- [ ] current branch is `feature/to-be-dev-env-bootstrap`
- [ ] target SHA is fixed before runtime start
- [ ] `.env.production` exists and is not tracked by Git
- [ ] `.env.production` starts with `GATEWAY_POLICY_PATH=infra/gateway/policies/cutover-isolation.yaml`
- [ ] `scripts/check-prod-secrets.ps1 -EnvFile .env.production` passes
- [ ] `post-cutover-write-open.yaml` exists and only changes `name` + `cutoverSwitches.blockLegacyWrites=false`

### B. Topology
- [ ] Mode A is used: container-network
- [ ] gateway can resolve these upstream names exactly:
  - [ ] `auth`
  - [ ] `member`
  - [ ] `board`
  - [ ] `quality-doc`
  - [ ] `order-lot`
  - [ ] `inventory`
  - [ ] `file`
  - [ ] `report`
- [ ] all upstream health endpoints respond `UP`

### C. Runtime / Rollback
- [ ] latest backup owner and restore owner confirmed
- [ ] `scripts/backup-db.ps1` execution path confirmed
- [ ] `scripts/restore-db.ps1` execution path confirmed
- [ ] rollback trigger owner confirmed
- [ ] evidence RunId created before runtime start

### D. Validation
- [ ] Phase A: migration dry-run PASS
- [ ] Phase A: gateway auth/member smoke PASS
- [ ] Phase B: gateway P0 smoke PASS after gateway-only restart
- [ ] `prod-down` and infra teardown completed

## 2) Required Commands

### 2.1 RunId / Evidence Root
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
$runId = "SCM-ACTUAL-TOPOLOGY-" + (Get-Date -Format "yyyyMMdd-HHmmss")
$ev = ".\runbooks\evidence\$runId"
New-Item -ItemType Directory -Force $ev | Out-Null
Set-Content .\.tmp\current-actual-topology-runid.txt $runId -Encoding UTF8
```

### 2.2 Phase A Policy: Freeze / Read-Only
```powershell
(Get-Content .\.env.production) `
  -replace '^GATEWAY_POLICY_PATH=.*$', 'GATEWAY_POLICY_PATH=infra/gateway/policies/cutover-isolation.yaml' `
  | Set-Content .\.env.production -Encoding UTF8

powershell -ExecutionPolicy Bypass -File .\scripts\check-prod-secrets.ps1 -EnvFile .env.production 2>&1 `
  | Tee-Object "$ev\check-prod-secrets.log"
```

### 2.3 Runtime Start + Topology Proof
```powershell
docker compose --env-file .env.production -f docker-compose.yml up -d sqlserver redis rabbitmq loki prometheus tempo grafana 2>&1 `
  | Tee-Object "$ev\infra-up.log"

docker compose --env-file .env.production -f docker-compose.yml -f docker-compose.actual-topology.yml up -d 2>&1 `
  | Tee-Object "$ev\actual-topology-up.log"

docker exec gateway getent hosts auth 2>&1 | Tee-Object "$ev\gateway-name-resolution-auth.log"
docker exec gateway getent hosts member 2>&1 | Tee-Object "$ev\gateway-name-resolution-member.log"
docker exec gateway getent hosts board 2>&1 | Tee-Object "$ev\gateway-name-resolution-board.log"
docker exec gateway getent hosts quality-doc 2>&1 | Tee-Object "$ev\gateway-name-resolution-quality-doc.log"
docker exec gateway getent hosts order-lot 2>&1 | Tee-Object "$ev\gateway-name-resolution-order-lot.log"
docker exec gateway getent hosts inventory 2>&1 | Tee-Object "$ev\gateway-name-resolution-inventory.log"
docker exec gateway getent hosts file 2>&1 | Tee-Object "$ev\gateway-name-resolution-file.log"
docker exec gateway getent hosts report 2>&1 | Tee-Object "$ev\gateway-name-resolution-report.log"

docker exec gateway wget -qO- http://auth:8081/actuator/health 2>&1 `
  | Tee-Object "$ev\gateway-auth-health.log"
```

### 2.4 Phase A Validation
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate migration-dry-run 2>&1 `
  | Tee-Object "$ev\gate-migration-dry-run.log"

$env:SCM_ENABLE_GATEWAY_E2E_SMOKE = "1"
$env:SCM_SQL_CONTAINER_NAME = "scm-sqlserver"
$env:SCM_ENV_FILE = ".env.production"
$env:SCM_DB_NAME = "SCM_RFT_PRODLIKE"

powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate smoke-test 2>&1 `
  | Tee-Object "$ev\gate-smoke-test.log"
```

### 2.5 Phase B Policy: Write Open + Gateway Restart
```powershell
(Get-Content .\.env.production) `
  -replace '^GATEWAY_POLICY_PATH=.*$', 'GATEWAY_POLICY_PATH=infra/gateway/policies/post-cutover-write-open.yaml' `
  | Set-Content .\.env.production -Encoding UTF8

docker compose --env-file .env.production -f docker-compose.yml -f docker-compose.actual-topology.yml up -d gateway --force-recreate 2>&1 `
  | Tee-Object "$ev\gateway-restart-write-open.log"

$null = Invoke-RestMethod http://localhost:18080/actuator/health 2>&1 `
  | Tee-Object "$ev\gateway-health-after-policy-switch.log"
```

- Wait until gateway health is UP after the force-recreate before running P0 smoke.

### 2.6 Phase B Validation
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\smoke-gateway-p0-e2e.ps1 `
  -GatewayBaseUrl "http://localhost:18080" `
  -Database "SCM_RFT_PRODLIKE" `
  -SqlContainerName "scm-sqlserver" `
  -EnvFile ".env.production" 2>&1 `
  | Tee-Object "$ev\smoke-gateway-p0-e2e.log"
```

### 2.7 Runtime Stop / Rollback Branch
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\prod-down.ps1 -RunId $runId 2>&1 `
  | Tee-Object "$ev\prod-down.log"

docker compose --env-file .env.production -f docker-compose.yml -f docker-compose.actual-topology.yml down 2>&1 `
  | Tee-Object "$ev\actual-topology-down.log"

docker compose --env-file .env.production -f docker-compose.yml down 2>&1 `
  | Tee-Object "$ev\infra-down.log"
```

- If rollback is triggered:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\restore-db.ps1 -EnvFile .env.production 2>&1 `
  | Tee-Object "$ev\restore-db.log"
```

## 3) Evidence File Paths

### Mandatory
- `runbooks/evidence/<RunId>/check-prod-secrets.log`
- `runbooks/evidence/<RunId>/actual-topology-up.log`
- `runbooks/evidence/<RunId>/gateway-name-resolution-auth.log` `runbooks/evidence/<RunId>/gateway-name-resolution-member.log` `runbooks/evidence/<RunId>/gateway-name-resolution-board.log` `runbooks/evidence/<RunId>/gateway-name-resolution-quality-doc.log` `runbooks/evidence/<RunId>/gateway-name-resolution-order-lot.log` `runbooks/evidence/<RunId>/gateway-name-resolution-inventory.log` `runbooks/evidence/<RunId>/gateway-name-resolution-file.log` `runbooks/evidence/<RunId>/gateway-name-resolution-report.log`
- `runbooks/evidence/<RunId>/gate-migration-dry-run.log`
- `runbooks/evidence/<RunId>/gate-smoke-test.log`
- `runbooks/evidence/<RunId>/gateway-restart-write-open.log`
- `runbooks/evidence/<RunId>/gateway-health-after-policy-switch.log`
- `runbooks/evidence/<RunId>/smoke-gateway-p0-e2e.log`
- `runbooks/evidence/<RunId>/prod-down.log`
- `runbooks/evidence/<RunId>/infra-down.log`
- `runbooks/evidence/<RunId>/decision-summary.md`

## 4) PASS Criteria
- Phase A uses `cutover-isolation.yaml`
- topology proof shows gateway can resolve and reach all upstream names
- migration dry-run PASS
- `smoke-test` PASS
- Phase B uses `post-cutover-write-open.yaml`
- gateway restart succeeds without full stack restart
- `smoke-gateway-p0-e2e.ps1` PASS
- all required evidence files exist

## 5) Stop Conditions
- any upstream service name cannot be resolved
- any upstream health endpoint is not `UP`
- migration dry-run FAIL
- auth/member smoke FAIL
- gateway restart after policy switch FAIL
- P0 smoke FAIL
- rollback trigger threshold exceeded

## 6) Final Decision Rule
- If both phases pass in the actual topology, the remaining DoD blocker is closed.
- If Phase A passes and Phase B fails only on write operations, fix post-cutover policy design and rerun Phase B.




