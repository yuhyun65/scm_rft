# Production Secret / Access Confirmation

## Scope
- Baseline branch: `feature/to-be-dev-env-bootstrap`
- Runtime baseline: `e464c2084eded932aeb07cb51300a67c19ecf62d`
- Release tag: `v2026.03.16-scm-rft-operational-go`
- Purpose: confirm the real production secret source and operational access path before cutover execution.

## 1) Secret Manager
| Item | Required Value | Status |
|---|---|---|
| Secret manager type | `Vault` / `AWS Secrets Manager` / `Azure Key Vault` / `Kubernetes Secret` / approved equivalent | `TBD` |
| Access client | CLI / SDK / runner path | `TBD` |
| Secret location | vault path / secret name / key vault name / namespace+secret | `TBD` |
| Read approver | owner name | `TBD` |

## 2) Operational Access Path
| Item | Required Value | Status |
|---|---|---|
| Deploy host or bastion | hostname / IP / runner name | `TBD` |
| Access method | `WinRM` / `SSH` / approved runner | `TBD` |
| Execution account | service account / operator account | `TBD` |
| DBA backup owner | name | `TBD` |
| Ops cutover owner | name | `TBD` |
| Go/No-Go approver | name | `TBD` |

## 3) Rendering Rules
1. `.env.production` is created only on the deploy host.
2. `.env.production` is never committed to Git.
3. Secret values come from the approved production secret source only.
4. Rendered file must pass `scripts/check-prod-secrets.ps1`.

## 4) Required Commands
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
git ls-files .env.production
powershell -ExecutionPolicy Bypass -File .\scripts\check-prod-secrets.ps1 -EnvFile .env.production
```

## 5) Cutover Entry Criteria
- Secret manager path confirmed
- Deploy host path confirmed
- `.env.production` rendered and validated
- Maintenance window approved
- Backup / restore owners confirmed
- `runbooks/cutover-day-runbook.md` and `runbooks/production-cutover-execution-checklist.md` accepted as execution baseline
