# Production Secret / Access Confirmation

## Scope
- Baseline branch: `feature/to-be-dev-env-bootstrap`
- Runtime baseline: `850c83c50fc2fb908f25c45affdce50a7ca72180`
- Release tag: `v2026.03.17-scm-rft-operational-go`
- Purpose: confirm the real production secret source and operational access path before cutover execution.

## How To Fill
1. Replace every `<fill>` field with an approved operational value.
2. Do not paste secret values into this document.
3. Record only the secret manager path/name and access route.
4. Keep `.env.production` off Git and render it only on the deploy host.

## 1) Secret Manager Confirmation
| Item | Actual Value | Format / Rule | Owner | Status |
|---|---|---|---|---|
| Secret manager type | `<fill>` | `Vault` / `AWS Secrets Manager` / `Azure Key Vault` / `Kubernetes Secret` / approved equivalent | Ops/Security | `OPEN` |
| Access client | `<fill>` | CLI / SDK / runner path | Ops | `OPEN` |
| Secret location | `<fill>` | vault path / secret name / key vault name / namespace+secret | Ops | `OPEN` |
| Read approver | `<fill>` | owner name | Project/Ops | `OPEN` |
| Render operator | `<fill>` | service account or operator account | Ops | `OPEN` |

## 2) Deploy Host / Bastion Confirmation
| Item | Actual Value | Format / Rule | Owner | Status |
|---|---|---|---|---|
| Deploy host or bastion | `<fill>` | hostname / IP / runner name | Ops | `OPEN` |
| Access method | `<fill>` | `WinRM` / `SSH` / approved runner | Ops | `OPEN` |
| Execution account | `<fill>` | service account / operator account | Ops | `OPEN` |
| Working directory | `C:\Users\CMN-091\projects\SCM_RFT` | fixed path on deploy host | Ops | `OPEN` |
| Production DB name | `<fill>` | actual production DB name | DBA | `OPEN` |

## 3) Owners / Approval / Window
| Item | Actual Value | Format / Rule | Owner | Status |
|---|---|---|---|---|
| DBA backup owner | `<fill>` | name | DBA | `OPEN` |
| DBA restore owner | `<fill>` | name | DBA | `OPEN` |
| Ops cutover owner | `<fill>` | name | Ops | `OPEN` |
| Go/No-Go approver | `<fill>` | name | Business/Ops | `OPEN` |
| Maintenance window start | `<fill>` | `YYYY-MM-DD HH:mm KST` | Project/Ops | `OPEN` |
| Maintenance window end | `<fill>` | `YYYY-MM-DD HH:mm KST` | Project/Ops | `OPEN` |
| Escalation channel | `<fill>` | Teams/Slack/phone bridge | Ops | `OPEN` |

## 4) Secret Rendering Rules
1. `.env.production` is created only on the deploy host.
2. `.env.production` is never committed to Git.
3. Secret values come from the approved production secret source only.
4. Rendered file must pass `scripts/check-prod-secrets.ps1`.
5. `GATEWAY_POLICY_PATH` must start with `infra/gateway/policies/cutover-isolation.yaml` and switch to `infra/gateway/policies/post-cutover-write-open.yaml` only after the write-open step in the cutover runbook.

## 5) Required Commands To Prove Readiness
### 5.1 Secret Source Access Check
```powershell
# Replace with the actual approved command for your secret manager.
<fill-secret-access-command>
```
Success condition:
- command exits `0`
- output proves the secret path/name exists
- output is saved to `runbooks/evidence/<RunId>/secret-source-check.log`

### 5.2 Deploy Host Access Check
```powershell
# Replace with the actual approved remote access command.
<fill-deploy-host-access-command>
```
Success condition:
- command exits `0`
- remote shell/session can access `C:\Users\CMN-091\projects\SCM_RFT`
- output is saved to `runbooks/evidence/<RunId>/deploy-host-access-check.log`

### 5.3 `.env.production` Validation On Deploy Host
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
git ls-files .env.production
powershell -ExecutionPolicy Bypass -File .\scripts\check-prod-secrets.ps1 -EnvFile .env.production
```
Success condition:
- `git ls-files .env.production` output = none
- `check-prod-secrets.ps1` PASS
- output is saved to `runbooks/evidence/<RunId>/env-precheck.log`

## 6) Cutover Entry Criteria
Mark every row `DONE` before actual production cutover starts.

| Check | Required Result | Status |
|---|---|---|
| Secret manager type fixed | no `<fill>` left | `OPEN` |
| Secret location fixed | no `<fill>` left | `OPEN` |
| Deploy host or bastion fixed | no `<fill>` left | `OPEN` |
| Access method fixed | no `<fill>` left | `OPEN` |
| DBA backup/restore owners fixed | both named | `OPEN` |
| Ops cutover owner fixed | named | `OPEN` |
| Go/No-Go approver fixed | named | `OPEN` |
| Maintenance window fixed | start/end written | `OPEN` |
| `.env.production` rendered on deploy host | yes | `OPEN` |
| `.env.production` validation PASS | yes | `OPEN` |

## 7) Final Sign Section
| Role | Name | Time (KST) | Decision |
|---|---|---|---|
| Ops Owner | `<fill>` | `<fill>` | `<fill>` |
| DBA | `<fill>` | `<fill>` | `<fill>` |
| Dev Owner | `<fill>` | `<fill>` | `<fill>` |
| Go/No-Go Approver | `<fill>` | `<fill>` | `<fill>` |
