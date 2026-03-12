# Frontend Modernization Process

- 문서명: `frontend_process.md`
- 기준일: 2026-03-12
- 기준 브랜치: `feature/to-be-dev-env-bootstrap`
- 원칙: `Issue 1개 = PR 1개 = 전용 브랜치 1개`

## 1. 목적
레거시 클라이언트(`xrw/ActiveX`) 의존 구간을 웹 표준 프론트엔드로 대체하고, 백엔드 MSA와 계약 기반으로 연동하여 Big-Bang 전환 시점에 운영 가능한 사용자 채널을 완성한다.

## 2. 범위
- 포함:
  - React + TypeScript + Vite 기반 웹 포털 구축
  - Auth/Member/Order-Lot/Board/Quality-Doc/Inventory/File/Report UI
  - Gateway 연계 인증/권한/에러 처리
  - OpenAPI 기반 API Client codegen 및 계약 테스트
  - 프론트 CI 게이트 추가 및 운영 전환 리허설 반영
- 제외:
  - 레거시 XRW 기능 신규 확장
  - 모바일 네이티브 앱 개발

## 3. 완료 기준(DoD)
1. 레거시 ActiveX 의존 화면 0개
2. P0 시나리오 E2E 통과율 100%
3. Contract mismatch 0건
4. 프론트 5게이트(빌드/유닛/계약/E2E/보안) 무스킵 PASS 1회 이상
5. 주요 성능 지표:
   - 로그인 p95 <= 500ms
   - 주문 목록 조회 p95 <= 800ms
   - 오류율(5xx) < 1%

## 4. 선행 조건
1. 백엔드 8개 서비스 API 엔드포인트가 최소 MVP 수준으로 기동 가능
2. `shared/contracts/*.openapi.yaml` 최신화
3. Gateway 정책(`timeout/retry/circuit-breaker/rate-limit`) 값 확정
4. 스테이징 SQL/메시지 브로커/모니터링 환경 기동 가능

## 5. 단계별 실행 절차

## 5.1 SCM-245: 프론트 베이스라인 구축
- 브랜치: `feature/scm-245-frontend-baseline`
- 작업:
  1. `frontend/apps/web-portal` 생성(React+TS+Vite)
  2. `frontend/packages/api-client` 생성(OpenAPI codegen)
  3. `frontend/packages/ui` 생성(공통 컴포넌트)
  4. `.github/workflows/ci-gates.yml`에 프론트 게이트 잡 추가
- 산출물:
  - `frontend/package.json` (workspace)
  - `frontend/apps/web-portal/*`
  - `frontend/packages/api-client/*`
  - `frontend/packages/ui/*`
- 검증:
  - `pnpm -C frontend install`
  - `pnpm -C frontend -r build`

## 5.2 SCM-246: Auth/Member UI MVP
- 브랜치: `feature/scm-246-auth-member-ui-mvp`
- 작업:
  1. 로그인 화면 + 토큰 저장/만료 처리
  2. 회원 상세/검색 화면
  3. 표준 에러 응답(`traceId`, `errorCode`) 공통 처리
- 검증:
  - 로그인 성공/실패 케이스
  - member search 페이징/필터 정상동작
- DoD(단계):
  - 로그인/회원조회 E2E PASS
  - 인증 실패율 < 1%

## 5.3 SCM-247: Order-Lot P0 UI MVP
- 브랜치: `feature/scm-247-orderlot-ui-mvp`
- 작업:
  1. 주문 목록/상세
  2. LOT 상세
  3. 주문 상태 변경(write)
  4. write API 재시도 금지 UX 반영(중복 클릭 방지/명시적 재시도 버튼)
- 검증:
  - 주문/LOT 조회 p95 <= 800ms
  - 상태 변경 성공률 >= 99%

## 5.4 SCM-248: Board + Quality-Doc UI MVP
- 브랜치: `feature/scm-248-board-qualitydoc-ui-mvp`
- 작업:
  1. Board 목록/상세/작성
  2. Quality-Doc 목록/상세/ACK
  3. ACK idempotent UX(동일 요청 재호출 시 동일 결과 표시)
  4. File 연계 실패(424/502) 에러 안내 일관화
- 검증:
  - ACK 중복 생성 0건
  - 첨부 연계 실패 시 사용자 안내/복구 경로 제공

## 5.5 SCM-249: Inventory + File + Report UI
- 브랜치: `feature/scm-249-inventory-file-report-ui`
- 작업:
  1. 재고 조회/변동 내역 화면
  2. 파일 업로드/다운로드 화면
  3. 리포트 요청/상태 조회 화면
- 검증:
  - 주요 조회 API 응답 성공률 >= 99%
  - 파일 업로드 실패 재현 시 에러 코드 매핑 100%

## 5.6 SCM-250: 통합 E2E + 컷오버 준비
- 브랜치: `feature/scm-250-frontend-e2e-cutover`
- 작업:
  1. P0 시나리오 E2E 통합
  2. 프론트 운영 Runbook/Smoke 스크립트 작성
  3. 리허설 증적 링크와 Go/No-Go 기준 연계
- 검증:
  - P0 E2E 100% PASS
  - Go/No-Go 지표에 프론트 항목 추가 완료

## 6. 구현 규칙
1. API 호출은 OpenAPI codegen 클라이언트만 사용한다.
2. 도메인별 폴더를 분리한다: `features/auth`, `features/member`, `features/order-lot` 등.
3. 공통 예외 처리/토스트/추적ID 노출은 `packages/ui` 단일 모듈에서 관리한다.
4. feature flag로 위험 기능의 점진 활성화를 제어한다.

## 7. 게이트 실행 표준
- 기존 필수 5게이트:
  - `build`
  - `unit-integration-test`
  - `contract-test`
  - `smoke-test`
  - `migration-dry-run`
- 프론트 추가 5게이트:
  - `frontend-build`
  - `frontend-unit-test`
  - `frontend-contract-test`
  - `frontend-e2e-smoke`
  - `frontend-security-scan`

### 7.1 로컬 실행 커맨드 (PowerShell)
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
pnpm -C .\frontend install
pnpm -C .\frontend -r build
pnpm -C .\frontend -r test
pnpm -C .\frontend -r lint
pnpm -C .\frontend --filter web-portal e2e
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate build
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate unit-integration-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate contract-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate smoke-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate migration-dry-run
```

## 8. 산출물 경로 규칙
- 계약(OpenAPI): `shared/contracts/`
- 이관 리포트: `migration/reports/`
- 운영/리허설: `runbooks/`
- 진행 QnA: `doc/QnA_보고서.md`
- 프론트 프로세스/결과: `doc/` 하위 문서

## 9. 리스크 및 즉시 대응
1. API 계약 드리프트 발생:
   - 대응: OpenAPI 갱신 -> codegen 재생성 -> contract-test 재실행
2. E2E 불안정(타임아웃/간헐 5xx):
   - 대응: gateway timeout/circuit-breaker 정책 확인 -> 재시도 1회 -> 로그/traceId 수집
3. 성능 미달(p95 초과):
   - 대응: 프론트 캐싱/페이지 크기 축소 -> 백엔드 쿼리/인덱스 튜닝 이슈 즉시 분리

## 10. 착수 체크리스트
1. `SCM-245` 이슈 생성 및 브랜치 생성 완료
2. 프론트 workspace 스캐폴딩 커밋 완료
3. Auth/Member 화면 MVP 동작 확인
4. Order-Lot P0 화면 MVP 동작 확인
5. 10게이트(기존5+프론트5) PASS 증적 확보
6. `doc/QnA_보고서.md`에 단계별 실행 이력 반영
