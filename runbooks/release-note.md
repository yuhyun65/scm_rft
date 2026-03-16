# Release Note

- Release Scope: `Final operational baseline after actual-topology validation`
- Branch: `feature/to-be-dev-env-bootstrap`
- Release Date: `2026-03-16`
- Release Tag: `v2026.03.16-scm-rft-operational-go`
- Runtime Baseline Commit: `e464c20`

## Changes
- Added `post-cutover-write-open.yaml` to reopen approved write traffic after freeze validation.
- Added `docker-compose.actual-topology.yml` for container-network actual topology rehearsal.
- Added `runbooks/actual-cutover-topology-rehearsal-runbook.md` for the two-phase policy switch flow.
- Updated `runbooks/go-nogo-signoff.md` with actual topology PASS evidence.
- Updated progress tracking and QnA log to reflect DoD blocker closure.

## Validation
- Actual topology RunId: `SCM-ACTUAL-TOPOLOGY-20260316-145704`
- Phase A (`cutover-isolation.yaml`): `migration-dry-run` PASS, `smoke-test` PASS
- Phase B (`post-cutover-write-open.yaml`): gateway-only restart PASS, `smoke-gateway-p0-e2e.ps1` PASS
- P0 E2E: `P0-F01~F07` PASS

## Evidence
- `runbooks/evidence/SCM-ACTUAL-TOPOLOGY-20260316-145704/decision-summary.md`
- `runbooks/evidence/SCM-ACTUAL-TOPOLOGY-20260316-145704/smoke-gateway-p0-e2e.log`
- `runbooks/evidence/SCM-ACTUAL-TOPOLOGY-20260316-145704/gate-migration-dry-run.log`
- `runbooks/evidence/SCM-ACTUAL-TOPOLOGY-20260316-145704/gate-smoke-test.log`

## Risks
- Remaining launch risks are operational ownership, secret rotation discipline, and execution timing.
- Current runtime/code DoD blockers are closed.

## Rollback
- `runbooks/rollback-playbook.md`
- `runbooks/hypercare-rollback-monitoring-checklist.md`
