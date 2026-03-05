# Rollback Time Evidence Runbook (SCM-226)

## Goal
Measure rollback restore time and archive reproducible evidence for Go/No-Go.

## DoD
- Restore command exit code is `0`.
- Measured rollback time is `<= 20 minutes`.
- Evidence files are created under `runbooks/evidence/<RunId>/`.

## Prerequisites
- Docker staging stack is running.
- SQL backup and restore scripts exist:
  - `scripts/backup-db.ps1`
  - `scripts/restore-db.ps1`
- `.env.staging` has valid `MSSQL_SA_PASSWORD`.

## Command
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\scm226-measure-rollback-time.ps1 `
  -RunId "SCM-226-$(Get-Date -Format yyyyMMdd-HHmmss)" `
  -Staging `
  -ThresholdMinutes 20
```

## DryRun (no backup/restore execution)
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\scm226-measure-rollback-time.ps1 `
  -RunId "SCM-226-DRYRUN-$(Get-Date -Format yyyyMMdd-HHmmss)" `
  -Staging `
  -DryRun
```

## Reuse Existing Backup (Optional)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\scm226-measure-rollback-time.ps1 `
  -RunId "SCM-226-REUSE-$(Get-Date -Format yyyyMMdd-HHmmss)" `
  -Staging `
  -SkipBackup `
  -BackupFile "MES_HI_YYYYMMDD-HHMMSS.bak" `
  -ThresholdMinutes 20
```

## Expected Output
- `runbooks/evidence/<RunId>/rollback-restore.log`
- `runbooks/evidence/<RunId>/rollback-health.log`
- `runbooks/evidence/<RunId>/rollback-time-summary.json`
- `runbooks/evidence/<RunId>/rollback-time-summary.md`
- `runbooks/evidence/<RunId>/backup.log` (if backup was executed)

## Signoff Update
After successful run, update:
- `runbooks/go-nogo-signoff.md`
  - Fill `Rollback time` metric using `rollback-time-summary.md`.
  - Change pending checkbox for rollback-time evidence to checked.

## Failure Handling
- If restore fails:
  - Inspect `rollback-restore.log`.
  - Stop signoff and mark `NO-GO`.
- If elapsed time exceeds threshold:
  - Mark `NO-GO`.
  - Record bottleneck and rerun after remediation.
