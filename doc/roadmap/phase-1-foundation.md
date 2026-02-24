# Phase 1: Repository Foundation, Templates, and CI Gates

## Objective
- establish repository baseline and enforced governance

## Scope
- branch and PR policy
- CI required gates
- toolchain lock and local bootstrap scripts
- agentic execution framework baseline

## Entry Criteria
- legacy mirror is available in repository
- feature branch is active

## Exit Criteria
- PR policy workflow active
- CI gate workflow active
- `check-prereqs`, `ci-run-gate`, `agentic-*` scripts validated
- runbooks/templates created

## Deliverables
- `.github/workflows/*.yml`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `toolchain.lock.json`
- `scripts/check-prereqs.ps1`
- `scripts/ci-run-gate.ps1`
