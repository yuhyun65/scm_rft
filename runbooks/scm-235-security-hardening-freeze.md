# SCM-235 Security Hardening Freeze Runbook

## Goal

Freeze security baseline for release by proving:
- High/Critical unresolved findings = 0
- Secret exposure pattern = 0
- Required gates pass with no [FAIL] and no [SKIP]

## Required Inputs

- Branch: feature/scm-235-security-hardening-freeze
- scripts/ci-run-gate.ps1 available

## Execution

```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\scm235-security-freeze.ps1 -RunId SCM-235-<YYYYMMDD-HHMMSS>
```

## Generated Evidence

- runbooks/evidence/SCM-235-<RunId>/gate-lint-static-analysis.log
- runbooks/evidence/SCM-235-<RunId>/gate-security-scan.log
- runbooks/evidence/SCM-235-<RunId>/security-freeze-summary.md
- runbooks/evidence/SCM-235-<RunId>/security-freeze-summary.json

## DoD (Measured)

- lint-static-analysis exit code = 0
- security-scan exit code = 0
- [FAIL] marker count = 0 (all required logs)
- [SKIP] marker count = 0 (all required logs)
- high unresolved findings = 0
- secret exposure patterns = 0

## Failure Handling

1. Stop and keep logs under same RunId.
2. Fix source of failure.
3. Re-run with a new RunId (no reuse).
4. Attach latest summary file to PR evidence comment.
