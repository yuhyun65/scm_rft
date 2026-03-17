# Production Secret / Access Confirmation (MOCK / REHEARSAL ONLY)

> WARNING
> - This document is for rehearsal, training, and documentation walkthrough only.
> - It is not valid for actual production approval or cutover execution.
> - Every value below is intentionally fake and prefixed with `MOCK-` or `EXAMPLE-`.

## Scope
- Baseline branch: `feature/to-be-dev-env-bootstrap`
- Runtime baseline: `850c83c50fc2fb908f25c45affdce50a7ca72180`
- Release tag: `v2026.03.17-scm-rft-operational-go`
- Mode: `REHEARSAL ONLY`
- Purpose: practice the production-input collection flow without using real operational values.

## 1) Secret Manager Confirmation
| Item | Actual Value | Format / Rule | Owner | Status |
|---|---|---|---|---|
| Secret manager type | `MOCK-Vault` | `Vault` / approved equivalent | Ops/Security | `MOCK-DONE` |
| Access client | `MOCK-vault.exe` | CLI / SDK / runner path | Ops | `MOCK-DONE` |
| Secret location | `MOCK-kv/scm/prod` | vault path / secret name | Ops | `MOCK-DONE` |
| Read approver | `MOCK-박운영` | owner name | Project/Ops | `MOCK-DONE` |
| Render operator | `MOCK-svc-scm-prod-deploy` | service account or operator account | Ops | `MOCK-DONE` |

## 2) Deploy Host / Bastion Confirmation
| Item | Actual Value | Format / Rule | Owner | Status |
|---|---|---|---|---|
| Deploy host or bastion | `MOCK-ops-bastion-01` | hostname / IP / runner name | Ops | `MOCK-DONE` |
| Access method | `MOCK-WinRM` | `WinRM` / `SSH` / approved runner | Ops | `MOCK-DONE` |
| Execution account | `MOCK-svc-scm-prod-deploy` | service account / operator account | Ops | `MOCK-DONE` |
| Working directory | `C:\Users\CMN-091\projects\SCM_RFT` | fixed path on deploy host | Ops | `MOCK-DONE` |
| Production DB name | `MOCK-MES_HI_PROD` | actual production DB name | DBA | `MOCK-DONE` |

## 3) Owners / Approval / Window
| Item | Actual Value | Format / Rule | Owner | Status |
|---|---|---|---|---|
| DBA backup owner | `MOCK-김DBA` | name | DBA | `MOCK-DONE` |
| DBA restore owner | `MOCK-이DBA` | name | DBA | `MOCK-DONE` |
| Ops cutover owner | `MOCK-최운영` | name | Ops | `MOCK-DONE` |
| Go/No-Go approver | `MOCK-박승인` | name | Business/Ops | `MOCK-DONE` |
| Maintenance window start | `2026-03-20 22:00 KST` | `YYYY-MM-DD HH:mm KST` | Project/Ops | `MOCK-DONE` |
| Maintenance window end | `2026-03-21 02:00 KST` | `YYYY-MM-DD HH:mm KST` | Project/Ops | `MOCK-DONE` |
| Escalation channel | `MOCK-Teams SCM-PROD bridge` | Teams/Slack/phone bridge | Ops | `MOCK-DONE` |

## 4) Secret Rendering Rules
1. `.env.production` is created only on the deploy host.
2. `.env.production` is never committed to Git.
3. Secret values come from the approved production secret source only.
4. Rendered file must pass `scripts/check-prod-secrets.ps1`.
5. `GATEWAY_POLICY_PATH` must start with `infra/gateway/policies/cutover-isolation.yaml` and switch to `infra/gateway/policies/post-cutover-write-open.yaml` only after the write-open step in the cutover runbook.
6. For this mock document, commands are illustrative only and must not be used as real production approval evidence.

## 5) Required Commands To Prove Readiness
### 5.1 Secret Source Access Check
```powershell
# MOCK command example only
vault kv get kv/scm/prod | Tee-Object .\runbooks\evidence\<RunId>\secret-source-check.log
```
Success condition:
- command exits `0`
- output proves the secret path/name exists
- output is saved to `runbooks/evidence/<RunId>/secret-source-check.log`

### 5.2 Deploy Host Access Check
```powershell
# MOCK command example only
Enter-PSSession -ComputerName ops-bastion-01 -Credential MOCK-svc-scm-prod-deploy
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
| Check | Required Result | Status |
|---|---|---|
| Secret manager type fixed | no `<fill>` left | `MOCK-DONE` |
| Secret location fixed | no `<fill>` left | `MOCK-DONE` |
| Deploy host or bastion fixed | no `<fill>` left | `MOCK-DONE` |
| Access method fixed | no `<fill>` left | `MOCK-DONE` |
| DBA backup/restore owners fixed | both named | `MOCK-DONE` |
| Ops cutover owner fixed | named | `MOCK-DONE` |
| Go/No-Go approver fixed | named | `MOCK-DONE` |
| Maintenance window fixed | start/end written | `MOCK-DONE` |
| `.env.production` rendered on deploy host | yes | `MOCK-DONE` |
| `.env.production` validation PASS | yes | `MOCK-DONE` |

## 7) Final Sign Section
| Role | Name | Time (KST) | Decision |
|---|---|---|---|
| Ops Owner | `MOCK-최운영` | `2026-03-20 21:45 KST` | `REHEARSAL GO` |
| DBA | `MOCK-김DBA` | `2026-03-20 21:46 KST` | `REHEARSAL GO` |
| Dev Owner | `MOCK-Codex` | `2026-03-20 21:47 KST` | `REHEARSAL GO` |
| Go/No-Go Approver | `MOCK-박승인` | `2026-03-20 21:48 KST` | `REHEARSAL GO` |

## 8) Quick Submission Form (Mock Example)
```text
[SCM_RFT Production Input Form - MOCK]
Secret manager type: MOCK-Vault
Access client: MOCK-vault.exe
Secret location: MOCK-kv/scm/prod
Read approver: MOCK-박운영
Render operator: MOCK-svc-scm-prod-deploy
Deploy host or bastion: MOCK-ops-bastion-01
Access method: MOCK-WinRM
Execution account: MOCK-svc-scm-prod-deploy
Production DB name: MOCK-MES_HI_PROD
DBA backup owner: MOCK-김DBA
DBA restore owner: MOCK-이DBA
Ops cutover owner: MOCK-최운영
Go/No-Go approver: MOCK-박승인
Maintenance window start: 2026-03-20 22:00 KST
Maintenance window end: 2026-03-21 02:00 KST
Escalation channel: MOCK-Teams SCM-PROD bridge
Approved secret access command: vault kv get kv/scm/prod
Approved deploy host access command: Enter-PSSession -ComputerName ops-bastion-01 -Credential MOCK-svc-scm-prod-deploy
Approved env render command: powershell -ExecutionPolicy Bypass -File .\scripts\render-prod-env-from-secretstore.ps1 -EnvFile .env.production
```
