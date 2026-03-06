# Reverse Snapshot Evidence Link

## Run Metadata
- RunId: `DB-RE-20260306-111448`
- GeneratedAt (KST): `2026-03-06 11:14:48`
- Source script: `scripts/reverse-export-schema.ps1`
- ERD script: `scripts/reverse-generate-erd.ps1`
- DB endpoint: `localhost,11433 / MES_HI`

## Snapshot Artifacts (Schema Evidence)
- `migration/reverse/DB-RE-20260306-111448/01_tables_columns.csv`
- `migration/reverse/DB-RE-20260306-111448/02_pk_uk_fk.csv`
- `migration/reverse/DB-RE-20260306-111448/03_indexes.csv`
- `migration/reverse/DB-RE-20260306-111448/04_constraints.csv`
- `migration/reverse/DB-RE-20260306-111448/05_sp_dependencies.csv`
- `migration/reverse/DB-RE-20260306-111448/06_rowcount.csv`
- `migration/reverse/DB-RE-20260306-111448/erd.mmd`
- `migration/reverse/DB-RE-20260306-111448/manifest.json`

## Snapshot Summary (Measured)
| Metric | Value |
|---|---:|
| tables | 13 |
| columns | 78 |
| PK | 13 |
| FK | 10 |
| indexes | 31 |
| constraints | 35 |
| sp dependencies | 0 |
| rowcount entries | 13 |

## Integrity Report Link (migration/reports)
- Latest validation report: `migration/reports/validation-20260305-165633.md`
- Latest dry-run state: `migration/reports/dryrun-20260305-165631.state.json`
- R1 measured runs (domain outputs):
  - `migration/reports/R1-SCM-225-20260305-R3-auth.out.txt`
  - `migration/reports/R1-SCM-225-20260305-R3-member.out.txt`
  - `migration/reports/R1-SCM-225-20260305-R3-file.out.txt`
  - `migration/reports/R1-SCM-225-20260305-R3-inventory.out.txt`
  - `migration/reports/R1-SCM-225-20260305-R3-report.out.txt`
  - `migration/reports/R1-SCM-225-20260305-R3-order-lot.out.txt`
  - `migration/reports/R1-SCM-225-20260305-R3-board.out.txt`
  - `migration/reports/R1-SCM-225-20260305-R3-quality-doc.out.txt`

## Decision
- This reverse snapshot is linked as structural evidence for migration report continuity.
- Next action: run domain validation SQL against this RunId baseline and append deltas in a new R1 measured file.
