# SCM-234 Observability and Alerting Runbook

## 1) Purpose
- Harden observability for production rehearsal baseline.
- Validate key metrics collection coverage:
  - 5xx error rate
  - p95 latency
  - p99 latency
  - RabbitMQ backlog
  - DB lock/deadlock counters

## 2) Preconditions
- Repository root: `C:\Users\CMN-091\projects\SCM_RFT`
- Docker Desktop running
- Infra stack up (`dev` or `staging`)
- Auth/member/gateway running and healthy (`8081/8082/18080`)

## 3) Infra restart (apply Prometheus rule/port changes)
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
docker compose down
docker compose up -d
```

For staging profile:
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
docker compose --env-file .env.staging -f docker-compose.staging.yml down
docker compose --env-file .env.staging -f docker-compose.staging.yml up -d
```

## 4) Verify endpoints
```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:9090/-/healthy
Invoke-WebRequest -UseBasicParsing http://localhost:15692/metrics
Invoke-WebRequest -UseBasicParsing http://localhost:3000/api/health
```

## 5) Run SCM-234 metrics collection
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\scm234-observability-check.ps1
```

Optional strict threshold validation:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\scm234-observability-check.ps1 -FailOnThreshold
```

## 6) Evidence
- Directory: `runbooks/evidence/SCM-234-<timestamp>/`
- Files:
  - `scm234-observability-summary.md`
  - `scm234-observability-summary.json`

## 7) Pass Criteria
- metrics collection coverage: `100%`
- `scm-core-alerts` rule group loaded
- no script failure

## 8) Gate sequence (required before PR merge)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate build
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate unit-integration-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate contract-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate lint-static-analysis
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate security-scan
$env:SCM_ENABLE_GATEWAY_E2E_SMOKE="1"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate smoke-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate migration-dry-run
```
