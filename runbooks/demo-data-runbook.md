# Demo Data Runbook

## Purpose
- Seed a richer, deterministic data set for browser demos.
- Keep smoke/P0 seed accounts compatible while adding more search results and status variety.
- Produce a summary file with the exact demo accounts and sample IDs.

## Preconditions
- Repository: `C:\Users\CMN-091\projects\SCM_RFT`
- Docker Desktop running
- SQL container running: `scm-sqlserver`
- `.env.production` present with `MSSQL_SA_PASSWORD`

## Execute
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT

docker compose --env-file .env.production -f docker-compose.yml up -d sqlserver
powershell -ExecutionPolicy Bypass -File .\scripts\seed-demo-data.ps1 `
  -Database "SCM_RFT_PRODLIKE" `
  -SqlContainerName "scm-sqlserver" `
  -EnvFile ".env.production"
```

## Output
- Script prints the summary path on success.
- A markdown summary is written to `runbooks/evidence/DEMO-SEED-<timestamp>/demo-seed-summary.md`.

## Demo Logins
- `smoke-user / password`
- `smoke-admin / password`
- `demo-buyer-001 / password`
- `demo-buyer-002 / password`
- `demo-quality-001 / password`
- `demo-warehouse-001 / password`
- `demo-ops-001 / password`
- `demo-vendor-alpha / password`
- `demo-vendor-beta / password`
- `demo-auditor-001 / password`
- `demo-viewer-001 / password`

## Recommended Search Keys
- Member search keyword: `demo`
- Order search keyword: `DEMO-ORDER`
- Board search keyword: `Demo`
- Quality-doc search keyword: `Demo`
- Inventory item code: `ITEM-001`
- Warehouse code: `WH-01`

## Recommended Detail IDs
- Order: `DEMO-ORDER-1002`
- Lot: `DEMO-LOT-1002-A`
- Board post: `55555555-5555-5555-5555-000000000002`
- Quality document: `66666666-6666-6666-6666-000000000002`
- File: `44444444-4444-4444-4444-000000000003`
- Report job: `77777777-7777-7777-7777-000000000001`

## Validation After Seeding
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\smoke-gateway-auth-member-e2e.ps1 `
  -GatewayBaseUrl "http://localhost:18080" `
  -AuthHealthUrl "http://localhost:8081/actuator/health" `
  -MemberHealthUrl "http://localhost:8082/actuator/health" `
  -GatewayHealthUrl "http://localhost:18080/actuator/health" `
  -Database "SCM_RFT_PRODLIKE" `
  -SqlContainerName "scm-sqlserver" `
  -EnvFile ".env.production" `
  -SeedData:$false
```

## Notes
- The script is idempotent. Re-running updates the same deterministic IDs.
- It does not delete data outside the fixed demo catalog.
- Use `post-cutover-write-open.yaml` if you want to demonstrate write actions in the browser.
