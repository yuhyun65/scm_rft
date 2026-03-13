# Production-Like Rehearsal Package

## Purpose
Package the exact inputs, commands, outputs, and acceptance criteria needed to execute one last production-like rehearsal before live cutover.

## Baseline
- Baseline branch: `feature/to-be-dev-env-bootstrap`
- Runtime baseline: `f6528a5c3379c696169fcea64458398f230e1acd`
- Recommended RunId pattern: `SCM-OPS-RH-<yyyyMMdd-HHmmss>`

## 1) Required Inputs
| Type | Path / Name | Required |
|---|---|---|
| prod env file | `.env.production` | Yes |
| baseline freeze | `runbooks/operational-baseline-freeze.md` | Yes |
| prod topology | `runbooks/prod-topology.md` | Yes |
| prod env inventory | `runbooks/prod-env-secrets-inventory.md` | Yes |
| cutover day runbook | `runbooks/cutover-day-runbook.md` | Yes |
| go/no-go signoff | `runbooks/go-nogo-signoff.md` | Yes |
| release note | `runbooks/release-note.md` | Yes |
| built jars | `services/*/build/libs/*.jar` | Yes |
| latest backup location | `migration/backups/` | Yes |

## 2) Execution Commands
### A. Validate prod secrets
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\check-prod-secrets.ps1 -EnvFile .env.production
```

### B. Start 9 services in prod profile
```powershell
$runId = "SCM-OPS-RH-$(Get-Date -Format yyyyMMdd-HHmmss)"
powershell -ExecutionPolicy Bypass -File .\scripts\prod-up.ps1 -RunId $runId -EnvFile .env.production -StopExistingPorts
```

### C. Rolling restart
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\prod-rolling-restart.ps1 -RunId $runId -EnvFile .env.production -RecoveryThresholdSec 300 -StopExistingPorts
```

### D. Stop services
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\prod-down.ps1 -RunId $runId
```

## 3) Mandatory Evidence
| Output | Expected Path |
|---|---|
| prod startup summary | `runbooks/evidence/<RunId>/prod-up-summary.md` |
| service pid state | `runbooks/evidence/<RunId>/prod-service-pids.json` |
| startup logs | `runbooks/evidence/<RunId>/up-*.out.log`, `up-*.err.log` |
| restart summary | `runbooks/evidence/<RunId>/prod-rolling-restart-summary.md` |
| restart logs | `runbooks/evidence/<RunId>/restart-*.out.log`, `restart-*.err.log` |
| stop summary | `runbooks/evidence/<RunId>/prod-down-summary.md` |
| P0 smoke result | attach or reference the post-start smoke run log |

## 4) Acceptance Criteria
1. `check-prod-secrets.ps1` PASS
2. `prod-up-summary.md` shows all 9 services `PASS`
3. `prod-rolling-restart-summary.md` shows all 9 services `PASS`
4. `TotalRecoverySec <= 300`
5. `prod-down-summary.md` shows all stop operations `PASS`
6. P0 smoke result PASS after startup

## 5) Stop Conditions
- missing `.env.production`
- any blocked default secret value
- any service health FAIL during startup
- rolling restart recovery time > 300 sec
- P0 smoke FAIL

## 6) Recommended Operator Set
- Dev Owner: service startup, P0 smoke, gateway policy
- Ops Owner: secret rendering, process ownership, monitoring
- DBA: backup/restore readiness and DB verification
- Codex: command sequence validation, evidence completeness, threshold review

## 7) Latest Executed Rehearsal
- ExecutedAt: `2026-03-13 18:11:32 KST`
- RunId: `SCM-OPS-RH-20260313-174920`
- EnvFile: `.env.production` (local untracked, prod-like values only)
- Verdict:
  - prod secret precheck: `PASS`
  - prod-up: `PASS`
  - rolling restart: `PASS`
  - total recovery: `215 sec`
  - gateway P0 smoke: `PASS`
  - prod-down: `PASS`
- Local evidence path:
  - `runbooks/evidence/SCM-OPS-RH-20260313-174920/prod-up-summary.md`
  - `runbooks/evidence/SCM-OPS-RH-20260313-174920/prod-rolling-restart-summary.md`
  - `runbooks/evidence/SCM-OPS-RH-20260313-174920/p0-smoke.log`
  - `runbooks/evidence/SCM-OPS-RH-20260313-174920/prod-down-summary.md`
- Blocking issues fixed during execution:
  1. `scripts/prod-orchestration-common.ps1`
     - `Ensure-PortFree` single-object listener handling patched
  2. `build.gradle`
     - added `org.flywaydb:flyway-sqlserver` so SQL Server 2022 (`16.0`) is supported in prod profile
  3. local prod-like gateway policy
     - rehearsal used `infra/gateway/policies/local-all-domains-e2e.yaml`
     - actual cutover must switch back to production-approved isolation policy
