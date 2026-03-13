# Cutover Day Runbook

## Scope
- Baseline branch: `feature/to-be-dev-env-bootstrap`
- Runtime baseline: `f6528a5c3379c696169fcea64458398f230e1acd`
- Reference docs:
  - `runbooks/cutover-operations-runbook.md`
  - `runbooks/cutover-checklist.md`
  - `runbooks/go-nogo-signoff.md`
  - `runbooks/prod-deploy-orchestration-runbook.md`

## Timebox Overview
| Time | Step | Owner | Command / Action | Stop Condition |
|---|---|---|---|---|
| T-90m | Go/No-Go reconfirm | Dev + Ops | verify signoff, freeze runtime baseline, confirm contacts | any required evidence missing |
| T-75m | Backup point creation | DBA + Dev | `scripts/backup-db.ps1 -EnvFile .env.production` | backup file missing or restore test unavailable |
| T-60m | Write freeze | Ops | apply gateway cutover isolation / emergency stop prep | legacy writes still accepted |
| T-45m | Final migration | Dev + DBA | run final migration sequence / dry-run verified path | migration failure or validation mismatch |
| T-30m | Production startup | Dev + Ops | `scripts/prod-up.ps1 -RunId <RunId> -EnvFile .env.production -StopExistingPorts` | any service health FAIL |
| T-20m | Gateway route open (read first) | Dev | enable read paths, auth verify, keep emergency stop ready | auth verify fail or 5xx spike |
| T-15m | P0 smoke | Dev + QA | login/member/order-lot/file/board/quality-doc/inventory/report smoke | any P0 failure |
| T-5m | Full traffic open | Ops | disable freeze, open standard gateway policy | latency/error threshold breach |
| T+15m | Hypercare wave 1 | Ops + Dev | watch 5xx/latency/backlog/deadlock/auth failures | threshold breach > 5 min |
| T+60m | Hypercare wave 2 | Ops + Dev | confirm stability and close emergency posture | unresolved alert or rollback criteria met |

## Detailed Steps
### 1) Go/No-Go Reconfirm (T-90m)
- Inputs:
  - `runbooks/go-nogo-signoff.md`
  - `runbooks/operational-baseline-freeze.md`
  - latest gate evidence and P0 smoke evidence
- Actions:
  1. Confirm runtime commit matches release baseline.
  2. Confirm `.env.production` is present and validated.
  3. Confirm rollback contacts and decision authority.
- DoD:
  - signoff evidence complete
  - deploy commit fixed
  - rollback owner named

### 2) Backup Point Creation (T-75m)
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\backup-db.ps1 -EnvFile .env.production
```
- Record backup file name in the cutover log.
- Stop if backup artifact cannot be verified.

### 3) Write Freeze (T-60m)
- Apply gateway isolation policy and announce write freeze.
- Keep emergency-stop parameters ready.
- Stop if legacy write traffic is still active.

### 4) Final Migration (T-45m)
- Run the approved migration path only.
- Record migration run id and validation summary.
- Stop if any critical mismatch appears.

### 5) Production Startup (T-30m)
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\prod-up.ps1 -RunId CUTOVER-$(Get-Date -Format yyyyMMdd-HHmmss) -EnvFile .env.production -StopExistingPorts
```
- Require all 9 services `UP` before continuing.

### 6) P0 Smoke Before Traffic Open (T-15m)
- Run auth/member/order-lot/file/board/quality-doc/inventory/report smoke in that order.
- Confirm gateway trace ids are captured.
- Stop if any smoke step fails once.

### 7) Full Traffic Open (T-5m)
- Open standard production gateway policy.
- Keep emergency stop reversible for the full hypercare window.
- Stop if 5xx, latency, or auth failure exceeds threshold.

### 8) Hypercare (T+15m to T+60m)
- Watch:
  - 5xx error rate
  - p95/p99 latency
  - DB deadlock / timeout
  - RabbitMQ backlog
  - auth failure rate
- If any metric crosses rollback threshold and persists, execute rollback playbook immediately.

## Rollback Trigger Summary
- backup unavailable or restore path unverified
- migration critical mismatch
- any required service health FAIL
- P0 smoke failure
- 5xx / latency / auth-failure threshold breach sustained beyond agreed window

## Primary Outputs
- backup artifact reference
- migration run id
- `prod-up-summary.md`
- P0 smoke result log
- final cutover decision note
