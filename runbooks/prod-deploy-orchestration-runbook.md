# SCM-233 Production Deploy Orchestration Runbook

## Purpose
Standardize production-like startup, shutdown, and rolling restart for all 9 services with reproducible evidence.

## Service Order
1. auth (8081)
2. member (8082)
3. file (8087)
4. board (8083)
5. quality-doc (8084)
6. order-lot (8085)
7. inventory (8086)
8. report (8088)
9. gateway (18080)

## Prerequisites
- `.env.production` exists and is validated.
- Built jars exist under `services/*/build/libs`.
- Port conflicts are resolved or run with `-StopExistingPorts`.

## 1) Validate Production Secrets
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\check-prod-secrets.ps1 -EnvFile .env.production
```

## 2) Start Services (prod profile)
```powershell
$runId = "SCM-233-$(Get-Date -Format yyyyMMdd-HHmmss)"
powershell -ExecutionPolicy Bypass -File .\scripts\prod-up.ps1 -RunId $runId -EnvFile .env.production -StopExistingPorts
```

Output:
- `runbooks/evidence/<RunId>/prod-up-summary.md`
- `runbooks/evidence/<RunId>/prod-service-pids.json`
- `runbooks/evidence/<RunId>/up-*.out.log`
- `runbooks/evidence/<RunId>/up-*.err.log`

## 3) Rolling Restart
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\prod-rolling-restart.ps1 -RunId $runId -EnvFile .env.production -RecoveryThresholdSec 300 -StopExistingPorts
```

Output:
- `runbooks/evidence/<RunId>/prod-rolling-restart-summary.md`
- updated `runbooks/evidence/<RunId>/prod-service-pids.json`
- `runbooks/evidence/<RunId>/restart-*.out.log`
- `runbooks/evidence/<RunId>/restart-*.err.log`

## 4) Stop Services
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\prod-down.ps1 -RunId $runId
```

Output:
- `runbooks/evidence/<RunId>/prod-down-summary.md`

## DoD
- Startup summary: all 9 services `PASS`.
- Rolling restart summary: all 9 services `PASS`.
- `TotalRecoverySec <= 300`.
- Shutdown summary: all process stop results `PASS`.
