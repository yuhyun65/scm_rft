# Final Pre-Deploy Gate Set

## Purpose
Define the exact gate sequence that must pass immediately before production cutover.

## Baseline
- Branch: `feature/to-be-dev-env-bootstrap`
- Runtime baseline: `f6528a5c3379c696169fcea64458398f230e1acd`
- Gate runner: `scripts/ci-run-gate.ps1`

## Host-Process Pre-Deploy Policy Rule
- If gateway and upstream services run as host processes on `localhost`, do not point pre-deploy smoke to `infra/gateway/policies/cutover-isolation.yaml` directly.
- Use `infra/gateway/policies/cutover-isolation-localhost.yaml` for pre-deploy only.
- Keep all timeout/retry/circuit-breaker/rate-limit/write-protection values identical to `cutover-isolation.yaml`.
- Actual cutover must switch back to `infra/gateway/policies/cutover-isolation.yaml`.

## 1) Required Gate Order
### Backend / Platform Gates
1. `build`
2. `unit-integration-test`
3. `contract-test`
4. `lint-static-analysis`
5. `security-scan`
6. `migration-dry-run`
7. `smoke-test`

### Frontend Gates
8. `frontend-build`
9. `frontend-unit-test`
10. `frontend-contract-test`
11. `frontend-e2e-smoke`
12. `frontend-security-scan`

### Deployment Precheck
13. `scripts/check-prod-secrets.ps1 -EnvFile .env.production`

## 2) Execution Commands
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate build
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate unit-integration-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate contract-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate lint-static-analysis
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate security-scan
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate migration-dry-run
$env:SCM_ENABLE_GATEWAY_E2E_SMOKE = "1"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate smoke-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate frontend-build
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate frontend-unit-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate frontend-contract-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate frontend-e2e-smoke
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate frontend-security-scan
powershell -ExecutionPolicy Bypass -File .\scripts\check-prod-secrets.ps1 -EnvFile .env.production
```

If the pre-deploy runtime is host-process based, set:
```powershell
(Get-Content .\.env.production) `
  -replace '^GATEWAY_POLICY_PATH=.*$', 'GATEWAY_POLICY_PATH=infra/gateway/policies/cutover-isolation-localhost.yaml' `
  | Set-Content .\.env.production -Encoding UTF8
```

## 3) Pass Criteria
- All 13 checks exit `0`
- Log contains `[FAIL]` zero times
- `.env.production` remains untracked
- no blocked default value in production secrets

## 4) Stop Conditions
- any gate FAIL
- smoke-test FAIL after retry
- frontend contract generation mismatch
- `.env.production` tracked or placeholder values detected

## 5) Evidence to Archive
- backend gate logs
- frontend gate logs
- prod secret precheck log
- latest smoke log
- latest migration dry-run log

## 6) Decision Rule
- Production cutover may start only after this full sequence passes against the frozen baseline.
