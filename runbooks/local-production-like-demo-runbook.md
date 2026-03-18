# Local Production-Like Demo Runbook

## Purpose
Run a production-like local demo on PC + Docker with:
- actual-topology container-network
- Phase A `cutover-isolation.yaml`
- optional Phase B `post-cutover-write-open.yaml`
- rich demo seed data
- optional frontend auto-launch

## Single Entry Script
- Script: [run-local-prodlike-demo.ps1](C:\Users\CMN-091\projects\SCM_RFT\scripts\run-local-prodlike-demo.ps1)

## Recommended Usage
### Full feature demo including write flows
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\run-local-prodlike-demo.ps1 -Mode FullFeature -LaunchFrontend
```

### Read-only demo
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\run-local-prodlike-demo.ps1 -Mode ReadOnly -LaunchFrontend
```

## What the Script Does
1. applies the project toolchain policy
2. validates local `.env.production`
3. sets Phase A gateway policy
4. starts infra containers
5. starts actual-topology application containers
6. seeds rich demo data
7. validates auth/member/gateway path
8. if `FullFeature`, switches to `post-cutover-write-open.yaml`, recreates gateway, waits for health up to `300s`, and runs full P0 smoke
9. optionally launches `frontend-dev.ps1` in a separate PowerShell window
10. writes a summary file under `runbooks/evidence/LOCAL-PRODLIKE-DEMO-<timestamp>/demo-launch-summary.md`

## Demo URLs
- Frontend: `http://localhost:5173`
- Gateway: `http://localhost:18080`

## Demo Accounts
- `smoke-user / password`
- `smoke-admin / password`
- `demo-buyer-001 / password`
- `demo-quality-001 / password`

## Suggested Demo Inputs
- Member keyword: `demo`
- Order detail ID: `DEMO-ORDER-1002`
- Lot detail ID: `DEMO-LOT-1002-A`
- Board keyword: `Demo`
- Quality-doc keyword: `Demo`
- Inventory item: `ITEM-001`
- Warehouse: `WH-01`
- File detail ID: `44444444-4444-4444-4444-000000000003`
- Report job detail ID: `77777777-7777-7777-7777-000000000001`

## Cleanup
### Single entry cleanup script
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\stop-local-prodlike-demo.ps1
```

### Manual cleanup
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
docker compose --env-file .env.production -f docker-compose.yml -f docker-compose.actual-topology.yml down
docker compose --env-file .env.production -f docker-compose.yml down
(Get-Content .\.env.production) `
  -replace '^GATEWAY_POLICY_PATH=.*$', 'GATEWAY_POLICY_PATH=infra/gateway/policies/cutover-isolation.yaml' `
  | Set-Content .\.env.production -Encoding UTF8
```
