# Cutover Document Freeze (SCM-238)

## Freeze Metadata
- Freeze ID: SCM-238-20260311-R1
- Effective At: 2026-03-11 16:21:32 +09:00
- Baseline Branch: feature/to-be-dev-env-bootstrap
- Baseline Commit: 6302532
- Issue: #53

## Freeze Scope
- The files below are frozen for cutover execution baseline.
- Any change requires: new Issue -> dedicated branch -> PR with reason and impact.
- Emergency hotfix is allowed only with explicit Go/No-Go approver signoff.

## Frozen Files (SHA256)
| File | SHA256 |
|---|---|
| $(@{path=runbooks/cutover-operations-runbook.md; sha256=96bb4b71cd30c2311373c6d1a477f6021c684bf18b7ab37d355e73250aa4ded8}.path) | $(@{path=runbooks/cutover-operations-runbook.md; sha256=96bb4b71cd30c2311373c6d1a477f6021c684bf18b7ab37d355e73250aa4ded8}.sha256) |
| $(@{path=runbooks/cutover-checklist.md; sha256=8ea22f265d1d1e671770410ba5f5f0b18468f6f58669b5648ad085e173235b36}.path) | $(@{path=runbooks/cutover-checklist.md; sha256=8ea22f265d1d1e671770410ba5f5f0b18468f6f58669b5648ad085e173235b36}.sha256) |
| $(@{path=runbooks/rollback-playbook.md; sha256=93b32a06d17082234c0c3ad5916d80bc34209c091412e24bb3d030cdaa7379f1}.path) | $(@{path=runbooks/rollback-playbook.md; sha256=93b32a06d17082234c0c3ad5916d80bc34209c091412e24bb3d030cdaa7379f1}.sha256) |
| $(@{path=runbooks/go-nogo-signoff.md; sha256=3e111c7aaf8afa836cf008ff1df4ec1eda3c5c0e812a1202bc26d3bb59c64f72}.path) | $(@{path=runbooks/go-nogo-signoff.md; sha256=3e111c7aaf8afa836cf008ff1df4ec1eda3c5c0e812a1202bc26d3bb59c64f72}.sha256) |
| $(@{path=runbooks/scm-236-cutover-migration-automation-runbook.md; sha256=ccf7828f6bad04eeb80523ffcad8716ccb525b8525d4654d01ad33318d63bcc6}.path) | $(@{path=runbooks/scm-236-cutover-migration-automation-runbook.md; sha256=ccf7828f6bad04eeb80523ffcad8716ccb525b8525d4654d01ad33318d63bcc6}.sha256) |
| $(@{path=runbooks/rehearsal-R1-runbook.md; sha256=b0ae869a0a362e1950063fd4f374feafd1c75a408b80fef8131b640db6c981aa}.path) | $(@{path=runbooks/rehearsal-R1-runbook.md; sha256=b0ae869a0a362e1950063fd4f374feafd1c75a408b80fef8131b640db6c981aa}.sha256) |
| $(@{path=runbooks/rollback-time-evidence-runbook.md; sha256=f9bbe94d10366ee5d5df06f6cc166114664d9695a7558902948de996921f5cb7}.path) | $(@{path=runbooks/rollback-time-evidence-runbook.md; sha256=f9bbe94d10366ee5d5df06f6cc166114664d9695a7558902948de996921f5cb7}.sha256) |
| $(@{path=runbooks/rollback-health-pass-runbook.md; sha256=dcb598d9f85dcd8ced877974d81916f91e13d3593cff3a248cd9dbcd36e2d235}.path) | $(@{path=runbooks/rollback-health-pass-runbook.md; sha256=dcb598d9f85dcd8ced877974d81916f91e13d3593cff3a248cd9dbcd36e2d235}.sha256) |

## Change Lock Rules
1. No direct push to baseline branch for frozen files.
2. PR title must include `scm-238-freeze-exception` for any exception.
3. Exception PR must attach before/after diff and rollback impact.

## Approval Record
| Role | Name | Time | Decision | Evidence |
|---|---|---|---|---|
| Dev Owner | CMN-091 | 2026-03-11 16:21:32 +09:00 | APPROVED | Issue #53 |
| Codex | GPT-5 Codex | 2026-03-11 16:21:32 +09:00 | APPROVED | Freeze manifest generated |

## Verification Commands
```powershell
$manifest = Get-Content .\runbooks\cutover-document-freeze.manifest.json | ConvertFrom-Json
$manifest.files | ForEach-Object {
  $actual = (Get-FileHash -Algorithm SHA256 $_.path).Hash.ToLower()
  if ($actual -ne $_.sha256) { throw "MISMATCH: $($_.path)" }
}
Write-Host "[OK] freeze manifest verified"
```
