# Production Cutover Gap Closure

## Scope
- Baseline branch: `feature/to-be-dev-env-bootstrap`
- Runtime baseline: `850c83c50fc2fb908f25c45affdce50a7ca72180`
- Release tag: `v2026.03.17-scm-rft-operational-go`
- Objective: close the remaining operational execution gaps before actual production cutover.

## Current State
Completed:
- Development DoD satisfied
- Final pre-deploy gates and actual-topology rehearsal PASS
- Cutover and signoff documents frozen

Open only for actual production execution:
- Real production secret manager source is not fixed in this session
- Deploy host or bastion access path is not fixed in this session
- Execution owners and approvers are not fixed in this session
- `.env.production` has not been rendered from the approved production secret source on the deploy host
- Actual production cutover has not been executed yet

## Execution Order
1. Fix production secret source
2. Fix deploy host or bastion path
3. Fix execution owners and maintenance window
4. Render `.env.production` on deploy host from the approved secret source
5. Validate `.env.production` on deploy host
6. Execute final cutover entry check
7. Execute actual production cutover
8. Execute hypercare and final closeout

## Step 1. Fix Production Secret Source
Required inputs:
- Secret manager type
- Access client or runner
- Secret location path or name
- Read approver

Owner:
- Ops Owner
- Security Owner

Fill in:
- `runbooks/production-secret-access-confirmation.md`
- `runbooks/prod-env-secrets-inventory.md`

Definition of done:
- Secret manager type is one of `Vault`, `AWS Secrets Manager`, `Azure Key Vault`, `Kubernetes Secret`, or approved equivalent
- Secret path or name is written with no `TBD`
- Read approver is named
- Secret access command succeeds once on the deploy host

Evidence:
- Secret lookup command output saved under `runbooks/evidence/<RunId>/secret-source-check.log`

## Step 2. Fix Deploy Host or Bastion Path
Required inputs:
- Deploy host or bastion hostname or IP
- Access method: `WinRM`, `SSH`, or approved runner
- Execution account

Owner:
- Ops Owner

Fill in:
- `runbooks/production-secret-access-confirmation.md`
- `runbooks/production-cutover-execution-checklist.md`

Definition of done:
- Deploy host or bastion is written with no `TBD`
- Access method is fixed
- Execution account is fixed
- One interactive or remote command succeeds on the deploy host

Evidence:
- Remote session proof saved under `runbooks/evidence/<RunId>/deploy-host-access-check.log`

## Step 3. Fix Owners and Maintenance Window
Required inputs:
- DBA backup owner
- Ops cutover owner
- Go/No-Go approver
- Maintenance window start and end time
- Escalation channel

Owner:
- Project Owner
- Ops Owner

Fill in:
- `runbooks/production-secret-access-confirmation.md`
- `runbooks/production-cutover-execution-checklist.md`
- `runbooks/cutover-day-runbook.md`

Definition of done:
- All owner fields have named persons or approved service accounts
- Maintenance window is fixed with date and time
- Escalation path is fixed

Evidence:
- Filled document snapshot under `runbooks/evidence/<RunId>/owner-window-confirmation.md`

## Step 4. Render `.env.production` on Deploy Host
Required inputs:
- Approved secret source from Step 1
- Deploy host path from Step 2
- Runtime baseline from the release tag

Owner:
- Ops Owner

Execution rule:
- Render only on the deploy host
- Never commit `.env.production`
- Use the production-approved gateway policy path

Validation commands:
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
git ls-files .env.production
powershell -ExecutionPolicy Bypass -File .\scripts\check-prod-secrets.ps1 -EnvFile .env.production
```

Definition of done:
- `git ls-files .env.production` output is empty
- `check-prod-secrets.ps1` PASS
- `.env.production` contains no placeholder or local rehearsal value

Evidence:
- `runbooks/evidence/<RunId>/env-render.log`
- `runbooks/evidence/<RunId>/env-precheck.log`

## Step 5. Final Cutover Entry Check
Required inputs:
- Filled `production-secret-access-confirmation.md`
- Validated `.env.production`
- Latest backup target and restore path

Owner:
- Dev Owner
- Ops Owner
- DBA

Execution baseline:
- `runbooks/production-cutover-execution-checklist.md`
- `runbooks/cutover-day-runbook.md`
- `runbooks/go-nogo-signoff.md`

Definition of done:
- Checklist section 0 and 1 all checked
- Backup path and restore owner recorded
- Go/No-Go decision is `GO`

Evidence:
- `runbooks/evidence/<RunId>/cutover-entry-check.md`

## Step 6. Execute Actual Production Cutover
Owner:
- Ops Owner runs commands
- DBA owns backup and restore
- Dev Owner validates smoke and P0

Execution order:
1. Announce cutover start
2. Freeze write traffic
3. Record backup file and migration run id
4. Execute final migration path
5. Start production services
6. Validate health and read smoke
7. Switch gateway policy from `cutover-isolation.yaml` to `post-cutover-write-open.yaml`
8. Restart gateway only
9. Run P0 smoke
10. Open standard production traffic

Key commands to prepare on deploy host:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\backup-db.ps1 -EnvFile .env.production
powershell -ExecutionPolicy Bypass -File .\scripts\prod-up.ps1 -RunId <RunId> -EnvFile .env.production -StopExistingPorts
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate migration-dry-run
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate smoke-test
powershell -ExecutionPolicy Bypass -File .\scripts\smoke-gateway-p0-e2e.ps1 -GatewayBaseUrl http://localhost:18080 -Database <ProdDbName> -EnvFile .env.production
```

Definition of done:
- `migration-dry-run` PASS
- `smoke-test` PASS
- `smoke-gateway-p0-e2e.ps1` PASS
- Gateway health and all domain health are `UP`
- No rollback trigger threshold exceeded

Evidence:
- `runbooks/evidence/<RunId>/gate-migration-dry-run.log`
- `runbooks/evidence/<RunId>/gate-smoke-test.log`
- `runbooks/evidence/<RunId>/smoke-gateway-p0-e2e.log`
- `runbooks/evidence/<RunId>/cutover-decision-summary.md`

## Step 7. Hypercare and Final Closeout
Owner:
- Ops Owner
- Dev Owner

Monitor:
- 5xx and 4xx rate
- p95 and p99 latency
- Auth failure rate
- DB deadlock and timeout
- Queue backlog

Definition of done:
- Metrics remain within thresholds during the agreed hypercare window
- Final decision note written
- Evidence shared to Dev, Ops, QA

Evidence:
- `runbooks/evidence/<RunId>/hypercare-summary.md`
- `runbooks/evidence/<RunId>/final-signoff-links.md`

## Missing Inputs Checklist
The following must be provided by the operator before actual cutover execution can start:
- Secret manager type
- Secret path or name
- Access client or runner
- Deploy host or bastion
- Access method
- Execution account
- DBA backup owner
- Ops cutover owner
- Go/No-Go approver
- Maintenance window
- Production DB name

## Current Verdict
- Development DoD: complete
- Production execution readiness: blocked until the missing inputs checklist is fully resolved
