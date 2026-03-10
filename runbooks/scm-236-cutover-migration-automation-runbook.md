# SCM-236 Cutover Migration Automation Runbook

## Goal

Automate cutover migration validation to produce measurable GO/NO-GO evidence.

## Required Conditions

- Branch: feature/scm-236-cutover-migration-automation
- SQL execution path available:
  - host sqlcmd OR
  - docker sqlcmd fallback (`scm-stg-sqlserver` or provided container)
- Env file includes `MSSQL_SA_PASSWORD` when not using trusted connection.

## Execution

```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\scm236-cutover-migration-automation.ps1 \
  -RunId SCM-236-<YYYYMMDD-HHMMSS> \
  -Server localhost,11433 \
  -TargetDatabase MES_HI \
  -EnvFile .env.staging \
  -SqlContainerName scm-stg-sqlserver \
  -UseDockerSqlcmd \
  -FailOnMismatch
```

## Output Artifacts

- `migration/reports/<RunId>-measured.md`
- `migration/reports/<RunId>-measured.json`
- `migration/reports/<RunId>-execution.md`
- `migration/reports/R1-<RunId>-<domain>.out.txt` (8 domains)
- `runbooks/evidence/<RunId>/scm236-cutover-summary.md`
- `runbooks/evidence/<RunId>/dry-run.log`
- `runbooks/evidence/<RunId>/r1-validation.log`

## DoD (Measured)

- count mismatch = 0
- sum delta <= 0.1%
- sample mismatch = 0/200
- status delta <= 1.0%p
- final verdict = GO

## Stop Conditions

- any step log contains `[FAIL]`
- domain metrics unresolved (`UNKNOWN`/`MISSING`) in measured report
- final verdict is NO-GO
