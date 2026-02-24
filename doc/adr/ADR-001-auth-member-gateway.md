# ADR-001: Auth/Member First with Gateway Enforcement

- Status: Accepted
- Date: 2026-02-24
- Owners: Developer, Codex

## Context
- Big-Bang 전환의 최대 실패 지점은 인증/권한/진입 제어 실패다.
- 기존 시스템은 단일 진입점과 SP 중심 구조로 도메인 분리가 약하며, 인증정보 노출 리스크가 높다.
- 1인 개발 체계에서는 도메인 전체를 동시에 구현하면 통합 리스크가 급격히 증가한다.

## Decision
- Phase 2에서 `auth`/`member`를 최우선으로 구현한다.
- 모든 후속 도메인 진입은 Gateway 정책을 통해 인증 전제 조건을 강제한다.
- 서비스 계약은 OpenAPI 우선(`auth.openapi.yaml`, `member.openapi.yaml`)으로 확정하고 이후 코드 생성/구현을 진행한다.
- 내부 상태 점검은 각 서비스 `/api/<service>/internal/health` 엔드포인트를 표준으로 둔다.

## Consequences
- 장점:
  - 인증 체계가 먼저 고정되어 이후 서비스의 보안 일관성을 확보한다.
  - 게이트웨이 정책 기준이 조기 확정되어 컷오버 통제가 단순해진다.
- 단점:
  - 초기에는 비즈니스 기능 가시성이 낮고, 도메인 기능 구현은 Phase 3 이후 집중된다.
  - Gateway/Auth 변경 시 영향 범위가 넓어 회귀 테스트 투자 필요성이 커진다.

## Follow-up
- `infra/gateway/policies/cutover-isolation.yaml`에 인증 연계 정책 상세화
- auth/member contract test를 CI 필수 게이트로 고정
- Token 구조/만료/재발급 정책은 ADR-002에서 별도 결정
