# User Demo Runbook

## Scope
- Repository: `C:\Users\CMN-091\projects\SCM_RFT`
- Target: local demo on PC + Docker + browser
- Frontend URL: `http://localhost:5173`
- Gateway URL: `http://localhost:18080`
- Demo accounts:
  - `smoke-user / password`
  - `smoke-admin / password`

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

## Terminal 1. Seed Demo Data
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\smoke-gateway-auth-member-e2e.ps1 `
  -GatewayBaseUrl "http://localhost:18080" `
  -AuthHealthUrl "http://localhost:8081/actuator/health" `
  -MemberHealthUrl "http://localhost:8082/actuator/health" `
  -GatewayHealthUrl "http://localhost:18080/actuator/health" `
  -Database "SCM_RFT_PRODLIKE" `
  -SqlContainerName "scm-sqlserver" `
  -EnvFile ".env.production"
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
- Login with:
  - `smoke-user / password`
  - or `smoke-admin / password`

## Demo Flow Order
1. Auth + Member
2. Order-Lot
3. Board + Quality-Doc
4. Inventory + File + Report
5. Cutover Runner

## Demo Pass Criteria
- Login succeeds and access token is shown
- Member search and detail return data
- Order and lot data return data
- Board and quality-doc lists return data
- Inventory, file, and report actions return data
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
