# User Demo Runbook

## Scope
- Repository: `C:\Users\CMN-091\projects\SCM_RFT`
- Target: local demo on PC + Docker + browser
- Frontend URL: `http://localhost:5173`
- Gateway URL: `http://localhost:18080`
- Demo accounts:
  - `smoke-user / password`
  - `smoke-admin / password`
  - `demo-buyer-001 / password`
  - `demo-quality-001 / password`

## Demo Mode
- Read-only demo:
  - keep `GATEWAY_POLICY_PATH=infra/gateway/policies/cutover-isolation.yaml`
- Full feature demo including write actions:
  - set `GATEWAY_POLICY_PATH=infra/gateway/policies/post-cutover-write-open.yaml`

Use full feature demo if you want to show:
- Order status change
- Board post create
- Quality-Doc ACK
- Report job create

## Demo Seed Rule
- Use only `scripts/seed-demo-data.ps1` for SCM_RFT demo data.
- Do not use `doc/seed-data-guide.md` or `sql/seed_data.sql` for the current SCM_RFT baseline.
- Canonical seed guide: `runbooks/demo-data-runbook.md`

## Terminal 1. Backend Start
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT

# For full feature demo only.
(Get-Content .\.env.production) `
  -replace '^GATEWAY_POLICY_PATH=.*$', 'GATEWAY_POLICY_PATH=infra/gateway/policies/post-cutover-write-open.yaml' `
  | Set-Content .\.env.production -Encoding UTF8

docker compose --env-file .env.production -f docker-compose.yml up -d sqlserver redis rabbitmq loki prometheus tempo grafana
docker compose --env-file .env.production -f docker-compose.yml -f docker-compose.actual-topology.yml up -d
```

## Terminal 1. Seed Rich Demo Data
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\seed-demo-data.ps1 `
  -Database "SCM_RFT_PRODLIKE" `
  -SqlContainerName "scm-sqlserver" `
  -EnvFile ".env.production"
```

Expected result:
- a summary file is written to `runbooks/evidence/DEMO-SEED-<timestamp>/demo-seed-summary.md`
- smoke accounts remain usable
- demo search/detail results now have enough rows for an actual walkthrough

## Terminal 1. Validate Auth + Member Path
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\smoke-gateway-auth-member-e2e.ps1 `
  -GatewayBaseUrl "http://localhost:18080" `
  -AuthHealthUrl "http://localhost:8081/actuator/health" `
  -MemberHealthUrl "http://localhost:8082/actuator/health" `
  -GatewayHealthUrl "http://localhost:18080/actuator/health" `
  -Database "SCM_RFT_PRODLIKE" `
  -SqlContainerName "scm-sqlserver" `
  -EnvFile ".env.production" `
  -SeedData:$false `
  -HealthWaitTimeoutSec 300
```

Expected result:
- auth/member/gateway health is waited automatically before login
- login PASS
- token verify PASS
- member search/detail PASS

## Terminal 2. Frontend Start
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\frontend-dev.ps1
```

Expected result:
- Vite dev server up on `http://localhost:5173`
- `/api/*` requests proxy to `http://localhost:18080`

## Browser Open
- Open `http://localhost:5173`
- Login with one of:
  - `smoke-user / password`
  - `smoke-admin / password`
  - `demo-buyer-001 / password`
  - `demo-quality-001 / password`

## Suggested Walkthrough Inputs
- Member keyword: `demo`
- Order detail ID: `DEMO-ORDER-1002`
- Lot detail ID: `DEMO-LOT-1002-A`
- Board keyword: `Demo`
- Quality-doc keyword: `Demo`
- Inventory item: `ITEM-001`, warehouse: `WH-01`
- File detail ID: `44444444-4444-4444-4444-000000000003`
- Report job detail ID: `77777777-7777-7777-7777-000000000001`

## Demo Flow Order
1. Login -> 거래처 관리 -> 거래처 상세 route
2. 주문 관리 -> 주문 상세 route
3. 게시판 -> 게시글 상세 route -> 파일 상세 route(첨부가 있을 때)
4. 품질 문서 -> 문서 상세/ACK route
5. 재고 현황 -> 재고 상세 route
6. 보고서 생성 -> 보고서 상세 route -> 파일 상세 route(output file이 있을 때)
5. Cutover Runner

## Demo Pass Criteria
- Login succeeds and dashboard로 이동한다
- Member search and detail route return data
- Order and lot data return data
- Board and quality-doc routes return data
- Inventory, report, and file detail routes return data
- No visible gateway/CORS error in browser

## Demo End / Cleanup
### Stop frontend
- stop the PowerShell session running `frontend-dev.ps1`

### Stop backend
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
docker compose --env-file .env.production -f docker-compose.yml -f docker-compose.actual-topology.yml down
docker compose --env-file .env.production -f docker-compose.yml down
```

### Restore default cutover policy
```powershell
(Get-Content .\.env.production) `
  -replace '^GATEWAY_POLICY_PATH=.*$', 'GATEWAY_POLICY_PATH=infra/gateway/policies/cutover-isolation.yaml' `
  | Set-Content .\.env.production -Encoding UTF8
```
