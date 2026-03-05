# SCM-214 Go/No-Go Sign-off (R1~R3)

## 1) Run Meta
- RunSet: `SCM-225-20260305-R1`, `SCM-225-20260305-R2`, `SCM-225-20260305-R3`
- Base branch: `feature/to-be-dev-env-bootstrap`
- Scope: `SCM-210~214`
- Decision time: `2026-03-05 14:20:00 KST`
- Evidence roots:
  - `runbooks/evidence/SCM-225-20260305-GATES/`
  - `runbooks/evidence/SCM-225-20260305-P0/`
  - `migration/reports/SCM-225-20260305-R*-measured.md`

## 2) Required Inputs
- [x] `runbooks/evidence/SCM-225-20260305-GATES/gate-build.log`
- [x] `runbooks/evidence/SCM-225-20260305-GATES/gate-unit-integration-test.log`
- [x] `runbooks/evidence/SCM-225-20260305-GATES/gate-contract-test.log`
- [x] `runbooks/evidence/SCM-225-20260305-GATES/gate-smoke-test.log`
- [x] `runbooks/evidence/SCM-225-20260305-GATES/gate-migration-dry-run.log`
- [x] `runbooks/evidence/SCM-225-20260305-P0/smoke-gateway-p0-e2e.log`
- [x] `migration/reports/SCM-225-20260305-R1-measured.md`
- [x] `migration/reports/SCM-225-20260305-R2-measured.md`
- [x] `migration/reports/SCM-225-20260305-R3-measured.md`

## 3) Global Metrics

| Metric | Evidence | Threshold | Measured | Result |
|---|---|---:|---:|---|
| 5xx error rate | `service-gateway.out.log` status summary (`5xx=0/31`) | `<=0.5%` | `0.00%` | PASS |
| 4xx error rate | `service-gateway.out.log` status summary (`401=2/31`, expected negative tests) | `<=8.0%` | `6.45%` | PASS |
| p95 latency | gateway request-id timing (stable window 13:59:25~13:59:27) | `<=350ms` | `192ms` | PASS |
| p99 latency | gateway request-id timing (stable window 13:59:25~13:59:27) | `<=700ms` | `192ms` | PASS |
| RabbitMQ backlog | `http://localhost:35672/api/queues` (`scm_stage`) | `ready<=1000, unacked<=500` | `ready=0, unacked=0` | PASS |
| DB deadlock/timeout | `Invoke-Sqlcmd` system_health last 10m | `deadlock=0, timeout<=3` | `0 / 0` | PASS |
| Data consistency | `SCM-225-20260305-R1~R3-measured.md` | `count=0, sum<=0.1%, sample=0/200, status<=1.0%p` | `3 runs, 8/8 PASS` | PASS |
| Rollback time | not executed in this stable path (`-SkipBackup`) | `<=20m` | `N/A` | N/A |
| Auth failure rate | auth route summary (`0/6`) | `<=3.0%` | `0.00%` | PASS |

## 4) Order-Lot Strict Metrics

| Metric | Evidence | Threshold | Measured | Result |
|---|---|---:|---:|---|
| 5xx error rate | order-lot API status summary (`0/4`) | `<=0.2%` | `0.00%` | PASS |
| p95 latency (read) | order-lot GET timing (`n=3`) | `<=250ms` | `189ms` | PASS |
| p99 latency (read) | order-lot GET timing (`n=3`) | `<=450ms` | `189ms` | PASS |
| Write failure rate | order-lot write (`POST status`, `0/1`) | `<=0.5%` | `0.00%` | PASS |
| Data consistency | order-lot rows in `SCM-225-20260305-R*-measured.md` | `count=0,sum<=0.05%,sample=0/200,status<=0.5%p` | `0/0/0/0` | PASS |
| DB deadlock/timeout | gateway/service logs + SQL check | `deadlock=0, timeout=0/10m` | `0 / 0` | PASS |

## 5) Final Decision
- [x] Required 5 gates passed
- [x] P0 E2E (F01~F07) passed
- [x] R1~R3 consistency checks passed
- [ ] Rollback-time measurement (`<=20m`) evidence still pending

**Decision:** `GO (R1~R3 rehearsal scope)`  
**Follow-up:** capture rollback-time evidence in the next rehearsal cycle.

## 6) Sign-off

| Role | Approver | Time (KST) | Decision | Evidence Link |
|---|---|---|---|---|
| Dev Owner | CMN-091 | 2026-03-05 14:20:00 | GO | `runbooks/rehearsals/R1-20260305.md` |
| Codex (Validation) | Codex | 2026-03-05 14:20:00 | GO | `migration/reports/SCM-225-20260305-R3-measured.md` |
| Ops Owner | CMN-091 | 2026-03-05 14:20:00 | GO | `runbooks/evidence/SCM-225-20260305-GATES/` |
| QA/Business Owner | CMN-091 | 2026-03-05 14:20:00 | GO | `runbooks/evidence/SCM-225-20260305-P0/smoke-gateway-p0-e2e.log` |

## 7) References
- `runbooks/rehearsal-R1-runbook.md`
- `runbooks/merge-gates-checklist.md`
- `runbooks/gateway-routing-matrix.md`
- `runbooks/rollback-playbook.md`
