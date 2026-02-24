# ADR-002: OrderLot and File as Core Migration Slice

- Status: Accepted
- Date: 2026-02-24
- Owners: Developer, Codex

## Context
- `sp_SCM_OrderManager`는 기능/라인 수가 큰 핵심 SP이며 Big-Bang 전환 리스크가 가장 높다.
- 첨부파일 경로는 데이터 정합성뿐 아니라 운영 장애(다운로드 실패, 경로 오류)로 직결된다.

## Decision
- Phase 3의 핵심 구현 단위를 `order-lot` + `file`로 묶어 단일 마이그레이션 슬라이스로 다룬다.
- `order-lot.openapi.yaml`, `file.openapi.yaml`을 기준 계약으로 고정하고, 이관 검증 기준표에 직접 매핑한다.
- 파일 메타데이터는 DB(`upload_files`)를 기준으로 검증하고, 실제 스토리지 경로 검증을 리허설 필수 항목으로 둔다.

## Consequences
- 장점:
  - 가장 위험한 데이터/업무 경로를 조기 검증해 컷오버 실패 확률을 낮춘다.
  - 이관 검증 리포트의 신뢰도를 핵심 도메인 기준으로 먼저 확보한다.
- 단점:
  - 초기 개발 난도가 높고, 인증/회원 이후 빠르게 데이터 설계 상세화가 필요하다.

## Follow-up
- `migration/mapping/legacy-sp-to-target-mapping.md`에서 OrderLot/File 항목 세분화
- 리허설 보고서에 파일 경로 유효성/다운로드 성공률 지표 추가
