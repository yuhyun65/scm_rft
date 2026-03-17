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

## Version-Control Candidates
These files can be committed only after explicit ownership and purpose are confirmed.
- `doc/seed-data-guide.md`
  - include if it becomes the canonical demo/seed operator guide for SCM_RFT
- `sql/seed_data.sql`
  - include if it is the maintained source-of-truth SQL for reusable demo/seed data provisioning

## Hold / Out Of Scope For SCM_RFT
These files should stay out of the repo unless the user explicitly decides SCM_RFT is the canonical home.
- `doc/HISCM_MSA_개발이력보고서.docx`

Reason:
- format-specific handoff/report artifact
- ownership and long-term maintenance target are not yet defined

## Working Rule
1. commit runtime/source changes only when they are referenced by code or runbooks
2. commit docs only when they have a clear owner and update path
3. keep scratch outputs in local exclude, not in Git history

## Local Exclude Rules
Add these patterns to `.git/info/exclude`:
- `_tmp_*`
- `frontend/_tmp_*`
