# Untracked File Policy

## Scope
- Branches: `feature/scm-252-frontend-redesign-foundation`, `feature/scm-253-frontend-redesign-docs`
- Date: 2026-03-17

## Immediate Exclude (Local Only)
These files are local scratch outputs and must not be committed.
- `_tmp_*`
- `frontend/_tmp_*`

Reason:
- generated during ad-hoc frontend/runtime checks
- no long-term ownership
- not referenced by runbooks or product documentation

## Exclude From SCM_RFT For Now
These files are not included in SCM_RFT at the current baseline.
- `doc/seed-data-guide.md`
- `sql/seed_data.sql`
- `doc/HISCM_MSA_개발이력보고서.docx`

Reason:
- `doc/seed-data-guide.md` and `sql/seed_data.sql` duplicate the current canonical demo-seed flow
  - canonical path: `scripts/seed-demo-data.ps1`
  - canonical operator doc: `runbooks/demo-data-runbook.md`
- the manual SQL path hardcodes database/schema assumptions and is not part of the validated gate/demo baseline
- `doc/HISCM_MSA_개발이력보고서.docx` is a format-specific handoff artifact whose canonical home is not fixed to SCM_RFT

## Working Rule
1. commit runtime/source changes only when they are referenced by code or runbooks
2. commit docs only when they have a clear owner and update path
3. keep scratch outputs in local exclude, not in Git history
4. keep one canonical seed path in SCM_RFT; do not version duplicate manual seed paths without an explicit replacement decision

## Local Exclude Rules
Add these patterns to `.git/info/exclude`:
- `_tmp_*`
- `frontend/_tmp_*`
- `doc/seed-data-guide.md`
- `sql/seed_data.sql`
- `doc/HISCM_MSA_개발이력보고서.docx`
