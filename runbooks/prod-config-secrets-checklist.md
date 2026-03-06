# SCM-232 Production Config/Secrets Checklist

## Scope
- Ensure production profile does not rely on insecure defaults.
- Enforce required secrets through environment variables.

## Required Files
- `.env.production` (local secure copy, not tracked)
- `.env.production.example` (template, tracked)
- `services/*/src/main/resources/application-prod.yml`

## Pre-Deploy Checks
1. Copy template:
```powershell
Copy-Item .\.env.production.example .\.env.production
```
2. Fill all `<...>` placeholders in `.env.production`.
3. Run secrets precheck:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check-prod-secrets.ps1 -EnvFile .env.production
```
4. Run mandatory local gates:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate build
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate unit-integration-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate security-scan
```

## DoD
- `check-prod-secrets.ps1` result: `FAIL count = 0`
- `SCM_AUTH_JWT_SECRET` length >= 32 and not default pattern
- `.env.production` is not tracked by git
- build/unit/security gates PASS
