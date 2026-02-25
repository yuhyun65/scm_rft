# ADR-005: Auth Token Policy and Gateway Validation

- Status: Accepted
- Date: 2026-02-25
- Owners: Developer, Codex

## Context
- `SCM-203` starts Auth token issue/verify and Member lookup API skeleton implementation.
- The project needs one fixed token format and one fixed gateway validation path before coding.
- Without this decision, auth/member/gateway implementation can diverge and break contract tests.

## Decision
- Token format:
  - Type: JWT access token
  - Signature: HS256
  - Expiration: 30 minutes (1800 seconds)
  - Required claims: `sub`, `roles`, `iat`, `exp`
- Validation flow:
  - Adopt `auth service introspection` as the only gateway validation strategy for `SCM-203`.
  - Gateway calls `/api/auth/v1/tokens/verify` and applies fail-closed behavior:
    - `active=true`: request can proceed.
    - `active=false` or verify call failure/timeout: request is rejected.
- Scope:
  - `SCM-203` does not implement refresh tokens.
  - Secret storage remains environment-based and is externalized (`SCM_AUTH_JWT_SECRET`).

## Consequences
- Pros:
  - Auth service becomes single source of truth for token validation policy.
  - Gateway logic stays simple and easier to change later.
  - Contracts map directly to implementation tasks (`login`, `verify`, `member by id`, `member search`).
- Cons:
  - Gateway adds network dependency on auth service for protected routes.
  - Need timeout/circuit-breaker handling in gateway for auth verification path.

## Follow-up
- Implement `AuthTokenProvider` and verify API in `services/auth`.
- Implement gateway auth filter and connect to `/api/auth/v1/tokens/verify`.
- Add contract and integration tests for reject/allow paths.

