# Roadmap

This directory operationalizes section 7 of `doc/scm_rft_design.md`.

## Phase Sequence
1. `phase-1-foundation.md`
2. `phase-2-auth-member-gateway.md`
3. `phase-3-orderlot-file.md`
4. `phase-4-remaining-domains.md`
5. `phase-5-rehearsal-cutover.md`

## Tracking
- source of truth: `progress.json`
- report command:
  - `powershell -ExecutionPolicy Bypass -File .\scripts\roadmap-report.ps1`
- issue/pr templates for `2.1`:
  - `doc/roadmap/issue-pr-templates-2.1.md`
- `SCM-201` outputs:
  - `doc/roadmap/scm-201-p0-scenarios.md`
  - `doc/adr/ADR-003-gateway-runtime-selection.md`
  - `doc/adr/ADR-004-shared-db-domain-schema-strategy.md`
