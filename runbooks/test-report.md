# Test Report (SCM-229)

- Issue: `SCM-229`
- Branch: `feature/scm-229-phase4-signoff-close`
- Date: `2026-03-05`

## Test Scope
- Current measured gates:
  - `lint-static-analysis`
  - `security-scan`
- Referenced baseline gates (previous closeout run):
  - `build`, `unit-integration-test`, `contract-test`, `smoke-test`, `migration-dry-run`

## Measured Results
| Gate | Command | Result | Evidence |
|---|---|---|---|
| lint-static-analysis | `ci-run-gate.ps1 -Gate lint-static-analysis` | PASS (`BUILD SUCCESSFUL in 26s`) | `runbooks/evidence/SCM-229/gate-lint-static-analysis.log` |
| security-scan | `ci-run-gate.ps1 -Gate security-scan` | PASS (`no obvious secret pattern detected`) | `runbooks/evidence/SCM-229/gate-security-scan.log` |

## Summary Counts
- Pass gates (current run): `2`
- Fail gates (current run): `0`
- Blocking defects found: `0`
- High risk findings: `0`

## Linked Baseline Evidence
- `runbooks/evidence/SCM-225-20260305-GATES/gate-build.log`
- `runbooks/evidence/SCM-225-20260305-GATES/gate-unit-integration-test.log`
- `runbooks/evidence/SCM-225-20260305-GATES/gate-contract-test.log`
- `runbooks/evidence/SCM-225-20260305-GATES/gate-smoke-test.log`
- `runbooks/evidence/SCM-225-20260305-GATES/gate-migration-dry-run.log`

## Notes
- Initial combined execution (`lint + security`) timed out due session timeout window.
- Re-ran `security-scan` independently and captured PASS evidence.
