# Daily Runbook - 2026-02-26 (SCM-210~214)

- 기준 브랜치: `feature/to-be-dev-env-bootstrap`
- 원칙: `Issue 1개 = PR 1개 = 전용 브랜치 1개`
- 필수 게이트: `build`, `unit-integration-test`, `contract-test`, `smoke-test`, `migration-dry-run`
- 산출물 경로:
  - 계약: `shared/contracts/`
  - 이관 리포트: `migration/reports/`
  - 운영/리허설: `runbooks/`
  - QnA: `doc/QnA_보고서.md`

## A. 타임라인(당일) + 병렬화

| 시간 | 트랙 A (개발자) | 트랙 B (Codex) | 체크포인트 | 산출물 | 실행 커맨드 |
|---|---|---|---|---|---|
| 09:00-09:20 | 환경/포트/시크릿 점검 | 게이트 사전 점검 | 시작 조건 충족 | 점검 로그 | `powershell -File .\\scripts\\check-prereqs.ps1` |
| 09:20-09:40 | SCM-210~214 이슈 생성 | 이슈 본문 템플릿 정리 | 이슈 5개 생성 | GitHub Issue | `gh issue create ...` |
| 09:40-10:00 | 브랜치 생성(210 우선) | 브랜치 규칙 점검 | 작업 브랜치 준비 | `feature/scm-210-*` 등 | `git switch -c feature/scm-210-order-lot-p0-mvp` |
| 10:00-12:00 | **SCM-210 구현 집중** | SCM-212 정책/SCM-213 SQL 템플릿 병행 | 210 API 골격 완성 | 코드+계약 | `./gradlew.bat :services:order-lot:test` |
| 13:00-14:00 | SCM-210 통합/성능 보강 | SCM-212 정책 파일 반영 | 210 1차 DoD | PR 초안 | `powershell -File .\\scripts\\ci-run-gate.ps1 -Gate contract-test` |
| 14:00-15:00 | SCM-211 구현 시작 | SCM-213 리포트 템플릿 생성 | 211 MVP 골격 | 코드+계약 | `./gradlew.bat :services:board:test :services:quality-doc:test` |
| 15:00-16:00 | SCM-212 라우팅 검증 | 도메인별 policy override 점검 | 전 도메인 route 점검 | 정책 파일 | `powershell -File .\\scripts\\ci-run-gate.ps1 -Gate smoke-test` |
| 16:00-17:00 | SCM-213 정합성 SQL 실행 | 증적 취합/리포트 정리 | R1 리포트 초안 | `migration/reports/*` | `powershell -File .\\scripts\\ci-run-gate.ps1 -Gate migration-dry-run` |
| 17:00-18:00 | SCM-214 리허설 R1 | Go/No-Go 초안 반영 | 당일 종료 판정 | runbook/update | `powershell -File .\\scripts\\rehearsal-run.ps1` |

병렬 원칙:
1. 개발자: SCM-210 구현 우선(대형 SP 리스크 구간).
2. Codex: SCM-212/213/214 문서/정책/증적 병렬 준비.
3. 오후에는 SCM-211을 병행하고, 최종 게이트는 일괄 실행.

## B. 이슈별 WBS

### SCM-210: Order-Lot P0 API MVP (최우선)

| Task | Owner | 입력/선행조건 | 작업절차 | 산출물 | DoD(측정 가능) | 검증 | 롤백/대응 |
|---|---|---|---|---|---|---|---|
| 계약 고정 | Dev+Codex | `order-lot.openapi.yaml`, legacy SP 분석 | P0 엔드포인트/에러코드 확정 | 계약 파일 | 계약 불일치 0건, 필수 응답코드 100% | `contract-test` | 계약 scope 축소 후 재고정 |
| 구현 | Dev | DB 스키마/인덱스 확인 | Controller/Service/Repo 구현 | `services/order-lot/*` | 조회 p95 <= 350ms, 오류율 < 1%, N+1 0건 | 단위+통합+실행계획 | 성능 미달 시 read-only 범위로 축소 |
| 게이트/PR | Dev+Codex | 구현 완료 | 게이트 실행/증적 첨부 | PR | 5개 게이트 pass 100% | `ci-run-gate.ps1` | 실패 항목 hotfix 후 재검증 |

### SCM-211: Board + Quality-Doc MVP

| Task | Owner | 입력/선행조건 | 작업절차 | 산출물 | DoD(측정 가능) | 검증 | 롤백/대응 |
|---|---|---|---|---|---|---|---|
| 계약 고정 | Codex | board/quality-doc 계약 초안 | 목록/상세/ack API 확정 | 계약 2종 | 계약 불일치 0건 | `contract-test` | 계약 scope 축소 |
| 구현 | Dev | file 연계 규칙 | API/Repo/에러응답 구현 | `services/board`, `services/quality-doc` | 조회 p95 <= 300ms, ack p95 <= 500ms, 오류율 < 1% | 모듈 테스트 | 첨부 장애 시 degrade 경로 적용 |
| 게이트/PR | Dev+Codex | 구현 완료 | 증적 첨부 PR | PR | 필수 게이트 pass 100% | 게이트 일괄 실행 | 문제 서비스만 선별 롤백 |

### SCM-212: Gateway 정책 전 도메인 확장

| Task | Owner | 입력/선행조건 | 작업절차 | 산출물 | DoD(측정 가능) | 검증 | 롤백/대응 |
|---|---|---|---|---|---|---|---|
| 정책 매트릭스 | Codex | 8개 도메인 목록 | timeout/retry/cb/rate-limit 정의 | 정책 표+yaml | 8도메인 route 로드 성공 100% | smoke + route 검증 | 문제 route disable |
| 구현/연결 | Dev | auth verify 연동 | route/filter/override 반영 | gateway 코드/정책 | gateway 오버헤드 p95 <= 30ms, 401/503 검증 100% | E2E smoke | emergency-stop ON 후 원복 |

### SCM-213: Migration 매핑/검증 R1

| Task | Owner | 입력/선행조건 | 작업절차 | 산출물 | DoD(측정 가능) | 검증 | 롤백/대응 |
|---|---|---|---|---|---|---|---|
| 매핑 확정 | Codex | legacy-to-target 매핑 | 도메인별 매핑표 완성 | `migration/mapping/*` | 매핑 누락 0건 | 리뷰 체크 | R1 범위 재조정 |
| 검증 SQL 실행 | Dev | 대상 DB/샘플데이터 | 건수/합계/샘플/상태분포 실행 | `migration/reports/R1-*.md` | count mismatch=0, sum 편차 <= 0.1%, sample mismatch=0/200, 상태편차 <= 1%p | SQL 결과 증적 | 임계치 초과 시 No-Go |

### SCM-214: 리허설 R1 + Go/No-Go 초안

| Task | Owner | 입력/선행조건 | 작업절차 | 산출물 | DoD(측정 가능) | 검증 | 롤백/대응 |
|---|---|---|---|---|---|---|---|
| 리허설 실행 | Dev+Codex | 컷오버/롤백 절차 | R1 시나리오 실행 | 리허설 기록 | 완료시간 <= 90분, 단계 누락 0건 | rehearsal 로그 | 타임라인 10분 초과 시 중단 |
| Go/No-Go 업데이트 | Codex | R1 결과 | 임계치 채움/판정 | `runbooks/go-nogo-signoff.md` | Critical 미해결 0건, 데이터 오차율 기준 충족 | signoff 점검 | 기준 미달 시 No-Go 선언 |

## C. 위험 레지스터 Top10

| 리스크 | 영향 | 탐지방법 | 완화책 | 에스컬레이션 트리거 |
|---|---|---|---|---|
| Order-Lot SP 의미 불일치 | 핵심 업무 오류 | 비교 SQL/샘플 검증 | read-first MVP | mismatch 1건 이상 |
| 숨은 부작용(트리거/배치) | 데이터 오염 | 트랜잭션 로그/영향 테이블 | 화이트리스트 관리 | 예상외 테이블 write 탐지 |
| Gateway 정책 과도/부족 | 장애/과부하 | 4xx/5xx 급증, p95 급등 | 도메인별 override | 오류율 > 2% 10분 지속 |
| 인증 전파 누락 | 보안 사고 | 보호 API 점검 | auth-required 검증 | 보호 API 200 발견 |
| 정합성 편차 | 컷오버 실패 | R1 SQL 4종 | 임계치 기반 판정 | count/sum 기준 초과 |
| 데이터 대표성 부족 | 허위 통과 | 분포 비교 | 실제 분포 반영 샘플 | 분포 편차 > 5%p |
| 성능 회귀 | UX 저하 | p95/p99 모니터링 | 쿼리/인덱스 튜닝 | p95 연속 초과 |
| 계약-코드 드리프트 | 통합 실패 | contract-test | PR 증적 강제 | contract-test fail |
| 롤백 절차 미완 | 복구 실패 | 역절차 리허설 | 롤백 시나리오 사전 검증 | 롤백 20분 초과 |
| 증적 누락 | 승인 지연 | 체크리스트 검수 | 산출물 위치 고정 | 필수 산출물 누락 |

## D. 체크리스트 3종

### 1) 시작 전
- [ ] 기준 브랜치 최신 동기화 (`git fetch --all --prune`)
- [ ] `.env` 시크릿(DB/JWT/RabbitMQ) 확인
- [ ] Docker/SQL/Redis/RabbitMQ 기동 확인
- [ ] 포트 충돌 없음 (`8081,8082,8085,8086,8087,8088,18080`)
- [ ] baseline smoke pass

### 2) 머지 전
- [ ] `build` pass
- [ ] `unit-integration-test` pass
- [ ] `contract-test` pass
- [ ] `smoke-test` pass
- [ ] `migration-dry-run` pass
- [ ] OpenAPI-코드 동기화 확인
- [ ] PR 본문에 증적 첨부
- [ ] `doc/QnA_보고서.md` 반영

### 3) 리허설 전
- [ ] 컷오버 타임라인 확정(T-시점~T+시점)
- [ ] 롤백 절차/담당/소요시간 확정
- [ ] Go/No-Go 임계치 수치 확정
- [ ] DB 백업/스냅샷 완료
- [ ] 모니터링 대시보드/알람 점검
- [ ] 리허설 기록 템플릿 준비

## 부록 1. Gateway 정책값 제안

기본값(공통):
- connect-timeout: `2000ms`
- response-timeout: `5000ms`
- retry: `2`(읽기만)
- circuit-breaker: `failureRate=50%`, `minCalls=20`, `waitOpen=10000ms`
- rate-limit: `80 rps` (burst 160)

| 도메인 | timeout(ms) | retry | CB failureRate | rate-limit(rps) | 예외/비고 |
|---|---:|---:|---:|---:|---|
| auth | 3000 | 1 | 40 | 120 | 로그인 지연 최소화 |
| member | 5000 | 2 | 50 | 100 | 기본값 근접 |
| file | 8000 | 1 | 50 | 60 | IO 경로 고려 |
| inventory | 5000 | 2 | 50 | 90 | 조회 중심 |
| report | 12000 | 0 | 30 | 40 | 생성 요청 재시도 금지 |
| order-lot | 10000 | 0(write)/1(read) | 30 | 30(write)/70(read) | 핵심 리스크 구간 |
| board | 5000 | 2 | 50 | 70 | 기본값 |
| quality-doc | 6000 | 1 | 40 | 60 | ACK 안정 우선 |

## 부록 2. Migration 검증 SQL 템플릿(건수/합계/샘플/상태분포)

공통 템플릿:
```sql
-- 1) 건수
SELECT '<domain>' AS domain, COUNT_BIG(*) AS cnt FROM <TARGET_TABLE>;

-- 2) 합계
SELECT '<domain>' AS domain, <SUM_EXPR> AS sum_metric FROM <TARGET_TABLE>;

-- 3) 샘플(상위 50)
SELECT TOP (50) <KEY_COLS> FROM <TARGET_TABLE> ORDER BY <ORDER_COL>;

-- 4) 상태분포
SELECT <STATUS_COL>, COUNT_BIG(*) AS cnt
FROM <TARGET_TABLE>
GROUP BY <STATUS_COL>
ORDER BY <STATUS_COL>;
```

도메인별 치환 기준:
1. auth: `dbo.auth_credentials`, `SUM(failed_count)`, 상태 `password_algo`
2. member: `dbo.members`, ACTIVE 카운트 합, 상태 `status`
3. file: `dbo.upload_files`, `DATALENGTH(storage_path)` 합, 상태 `domain_key`
4. inventory: `dbo.inventory_balances`/`dbo.inventory_movements`, `SUM(quantity)`, 상태 `movement_type`
5. report: `dbo.report_jobs`, FAILED 카운트 합, 상태 `status`
6. order-lot: `dbo.orders`/`dbo.order_lots`, `SUM(quantity)`, 상태 `status`
7. board: `dbo.board_posts`, notice 카운트 합, 상태 `status`
8. quality-doc: `dbo.quality_documents`/`dbo.quality_document_acks`, ack count, 상태 `status`

R1 판정 임계치:
- count mismatch: `0`
- sum 편차: `<= 0.1%`
- sample mismatch: `0/200`
- 상태분포 편차: `<= 1.0%p`
