# Release Note

- Release Scope: `Superseding operational baseline after frontend redesign sync and browser demo revalidation`
- Branch: `feature/to-be-dev-env-bootstrap`
- Release Date: `2026-03-17`
- Release Tag: `v2026.03.17-scm-rft-operational-go`
- Runtime Baseline Commit: `850c83c`

## Changes
- Merged frontend routed shell foundation into the baseline branch.
- Added frontend redesign process/docs bundle and operator guidance.
- Kept canonical demo seed flow on `scripts/seed-demo-data.ps1` + `runbooks/demo-data-runbook.md`.
- Added readiness-safe auth/member demo smoke behavior for cold-start local validation.
- Revalidated the browser demo path on the merged current base.

## Validation
- Actual topology RunId: `SCM-ACTUAL-TOPOLOGY-20260316-145704`
- Actual topology result: `migration-dry-run` PASS, `smoke-test` PASS, `smoke-gateway-p0-e2e.ps1` PASS
- Browser demo revalidation RunId: `BASELINE-DEMO-REVALIDATE-20260317-132414`
- Browser demo revalidation result: SQL readiness PASS, demo seed PASS, gateway auth/member smoke PASS, frontend origin load PASS, frontend proxy login PASS

## Evidence
- `runbooks/evidence/SCM-ACTUAL-TOPOLOGY-20260316-145704/decision-summary.md`
- `runbooks/evidence/SCM-ACTUAL-TOPOLOGY-20260316-145704/smoke-gateway-p0-e2e.log`
- `runbooks/evidence/BASELINE-DEMO-REVALIDATE-20260317-132414/baseline-demo-revalidation-summary.md`
- `runbooks/evidence/BASELINE-DEMO-REVALIDATE-20260317-132414/proxy-login-response.json`

## Risks
- Remaining launch risks are operational ownership, secret rotation discipline, and execution timing.
- Current runtime/code DoD blockers are closed; actual production entry is still blocked by unresolved secret/access inputs.

## Rollback
- `runbooks/rollback-playbook.md`
- `runbooks/hypercare-rollback-monitoring-checklist.md`
