# Production Cutover Execution Checklist

## 0) Secret Manager / Operational Access Confirmation
- [ ] secret manager type fixed (`Vault` / `AWS Secrets Manager` / `Azure Key Vault` / `Kubernetes Secret` / approved equivalent)
- [ ] secret manager access path fixed (vault path, secret name, key vault name, namespace/secret, or equivalent)
- [ ] deploy host or bastion fixed
- [ ] deploy host access method fixed (`WinRM` / `SSH` / approved runner)
- [ ] `.env.production` rendered on deploy host from the approved secret source
- [ ] `git ls-files .env.production` output = none
- [ ] `scripts/check-prod-secrets.ps1 -EnvFile .env.production` PASS
- [ ] DBA backup/restore owner fixed
- [ ] Ops cutover owner fixed
- [ ] maintenance window and Go/No-Go approver confirmed

## 1) Go / No-Go
- [ ] `runbooks/go-nogo-signoff.md` latest decision is `GO`
- [ ] `runbooks/operational-baseline-freeze.md` matches target runtime commit
- [ ] `runbooks/final-predeploy-gates.md` full sequence PASS
- [ ] `.env.production` validated by `scripts/check-prod-secrets.ps1`
- [ ] latest backup location and restore owner confirmed
- [ ] communication channel and escalation contact list confirmed

## 2) Cutover Start
- [ ] announce cutover start time
- [ ] freeze write traffic on gateway
- [ ] record backup file name and migration run id
- [ ] confirm legacy traffic reduction or maintenance notice active

## 3) Migration / Startup
- [ ] execute final migration path only
- [ ] confirm migration validation mismatch critical = 0
- [ ] run `scripts/prod-up.ps1` with current RunId
- [ ] confirm all 9 services health = `UP`

## 4) Validation Before Traffic Open
- [ ] auth login PASS
- [ ] member search/detail PASS
- [ ] order-lot P0 flow PASS
- [ ] board + quality-doc PASS
- [ ] inventory + file + report PASS
- [ ] gateway trace ids captured for all smoke paths

## 5) Traffic Open
- [ ] enable standard production gateway policy
- [ ] open read traffic
- [ ] open write traffic
- [ ] confirm no immediate 5xx spike

## 6) Abort / Rollback Branch
Trigger rollback immediately if any of the following occurs:
- [ ] migration critical mismatch
- [ ] any required service remains `DOWN`
- [ ] P0 smoke FAIL
- [ ] 5xx / latency / auth failure exceeds rollback threshold and persists

If triggered:
- [ ] apply emergency stop on gateway
- [ ] execute `scripts/restore-db.ps1`
- [ ] reopen legacy traffic path
- [ ] record incident timeline and rollback evidence

## 7) Completion
- [ ] hypercare monitoring active
- [ ] cutover decision note written
- [ ] final evidence paths shared to Dev/Ops/QA
