# SCM-203 Scope Lock

- Issue: `#6`
- Branch: `feature/scm-203-auth-member-mvp`
- Date: 2026-02-25

## Objective
Deliver implementation skeleton for auth/member/gateway handoff before domain expansion.

## Locked Scope
- Auth (`services/auth`)
  - Controller: login, token verify endpoints
  - Service: credential check + token issue/verify orchestration
  - TokenProvider: HS256 JWT issue/verify
  - Error response model: unified API error body
- Member (`services/member`)
  - Controller: get member by id, search members
  - Service: query orchestration and DTO mapping
  - Repository: JDBC query baseline for single/read-list
- Gateway (`services/gateway`)
  - Auth filter for protected routes
  - `/api/auth/v1/tokens/verify` integration point
  - Route protection behavior: fail-closed on verify failure

## Out Of Scope
- Refresh token lifecycle
- Full RBAC policy engine
- Legacy SP full feature parity

## Entry Criteria (all required)
- `shared/contracts/auth.openapi.yaml` includes `login`, `token verify`
- `shared/contracts/member.openapi.yaml` includes `member by id`, `member search`
- ADR token policy is accepted (`ADR-005`)
- Flyway member lookup prep is ready (`V3__auth_member_lookup_indexes.sql`)

## Done Criteria (for SCM-203 PR)
- Required controllers/services/repositories/filter exist and build
- Gates pass: `build`, `unit-integration-test`, `contract-test`, `smoke-test`
- Evidence updated: ADR, roadmap progress, runbook/test notes as needed

