# Evidence Manifest

This directory stores tracked evidence manifests for release/audit.

## Files
- `<RunId>-manifest.json`: file-level SHA256 manifest.
- `<RunId>-manifest.md`: human-readable summary table.

## Generation
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish-evidence-manifest.ps1 -RunId SCM-237-20260311-R4
```

## Verification
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish-evidence-manifest.ps1 -RunId SCM-237-20260311-R4 -VerifyOnly
```
