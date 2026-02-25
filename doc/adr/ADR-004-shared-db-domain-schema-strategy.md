# ADR-004: Shared DB with Domain-Oriented Schema Strategy

- Status: Accepted
- Date: 2026-02-25
- Owners: Developer, Codex

## Context
- Big-Bang 전환 초기에는 데이터 정합성 검증과 이관 리허설 반복이 핵심이다.
- 서비스별 물리 DB 완전 분리는 초기 운영 복잡도와 이관 난이도를 크게 높인다.
- 현재 마이그레이션 자산은 SQL Server 단일 인스턴스 기준으로 준비되어 있다.

## Decision
- 1단계(2.1 달성 전): `공유 SQL Server + 도메인 테이블 분리` 전략을 채택한다.
- DB 변경은 Flyway 버전 마이그레이션으로만 반영한다.
- 도메인 경계를 코드 계층(service/repository)과 계약(OpenAPI)으로 우선 강제한다.
- FK/인덱스/상태 제약을 통해 데이터 무결성을 우선 확보한다.

## Consequences
- 장점:
  - 초기 구현/운영 복잡도를 줄이고 P0 기능 출시 속도를 확보한다.
  - 이관 검증 쿼리 작성이 단순해 리허설 반복이 쉽다.
- 단점:
  - 물리적 격리가 없어 도메인 간 DB 의존이 다시 생길 수 있다.
  - 향후 서비스별 DB 분리 시 추가 리팩토링이 필요하다.

## Follow-up
- `SCM-205`에서 서비스별 DB 접근 경계 규칙(직접 타도메인 조회 금지) 적용
- 마이그레이션 리포트에 도메인별 정합성 지표 분리
- 안정화 단계에서 DB 분리 후보 도메인(order-lot, file) 우선 검토
