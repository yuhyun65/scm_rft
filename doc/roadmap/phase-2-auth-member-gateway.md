# Phase 2: Auth/Member and Gateway First

## Objective
- deliver authentication and membership core with gateway enforcement

## Scope
- auth service skeleton and API contract
- member service skeleton and API contract
- gateway routing and access policy baseline

## Entry Criteria
- phase 1 completed
- OpenAPI/ADR template ready

## Exit Criteria
- auth/member contracts published
- basic token flow documented
- gateway policy file mapped to auth/member routes
- contract and smoke gate pass

## Deliverables
- `shared/contracts/auth.openapi.yaml`
- `shared/contracts/member.openapi.yaml`
- `doc/adr/ADR-*-auth-member-gateway.md`
- `infra/gateway/policies/*.yaml`
