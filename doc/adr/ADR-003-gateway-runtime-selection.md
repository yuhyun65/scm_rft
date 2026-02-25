# ADR-003: Gateway Runtime Selection

- Status: Accepted
- Date: 2026-02-25
- Owners: Developer, Codex

## Context
- `dev_plan.md` 2.1 완료 조건에는 Gateway 수준의 인증/권한/격리/긴급차단이 포함된다.
- 현재 저장소에는 gateway 정책 YAML만 존재하고 실행체가 없어 런타임 검증이 불가능하다.
- 1인 개발 체계에서는 운영 난이도가 낮고 코드 기반 정책 확장이 쉬운 선택이 필요하다.

## Decision
- Gateway 실행체를 `Spring Cloud Gateway`로 표준화한다.
- Gateway는 별도 서비스(`services/gateway`)로 운영한다.
- 라우팅/타임아웃/재시도/서킷브레이커/긴급차단 정책은 `infra/gateway/policies/*.yaml`에서 로드한다.
- 모든 외부 API 요청은 Gateway 단일 진입점으로 고정한다.

## Consequences
- 장점:
  - 기존 Java/Spring 스택과 일관성이 높아 구현/운영 복잡도가 낮다.
  - 정책/필터를 코드와 문서로 함께 관리할 수 있다.
- 단점:
  - Gateway 서비스 장애 시 전체 API 영향이 커져 가용성 설계가 필요하다.
  - 고급 트래픽 관리 기능은 추가 구현이 필요할 수 있다.

## Follow-up
- `SCM-202`에서 `services/gateway` 모듈 구현
- 인증 필터와 emergency stop 스위치 구현
- P0 E2E 테스트를 gateway 경유로 전면 전환
