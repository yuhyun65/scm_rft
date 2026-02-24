# Big-Bang Rehearsal Runbook

## Objective
- rehearse a production-like cutover in isolated staging environment
- validate migration repeatability and data correctness

## Prerequisites
- `.env.staging` prepared
- staging stack up (`scripts/staging-up.ps1`)
- migration source snapshot secured

## Procedure
1. Bring up staging stack
2. Run migration dry-run (`migration/scripts/dry-run.ps1`)
3. Run validation (`migration/verify/validate-migration.ps1`)
4. Archive validation report and dry-run state file
5. Execute restore rehearsal from latest backup

## Acceptance Criteria
- no failed checks in validation report
- migration dry-run state reaches `completed`
- restore procedure completed within agreed RTO

## Evidence
- `migration/reports/validation-*.md`
- `migration/reports/dryrun-*.state.json`
- backup file name and restore execution log
