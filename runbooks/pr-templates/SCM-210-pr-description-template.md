# [SCM-210] Order-Lot P0 API MVP

## 배경/목표
- 레거시 `sp_SCM_OrderManager` 대형 SP 의존 구간을 API 기반으로 전환한다.
- Order/Lot 핵심 경로를 P0 범위로 구현해 Big-Bang 전환 리스크를 선제 제거한다.

## 범위(in/out)
- In:
  - Order 생성/조회 API
  - Lot 할당/조회 API
  - 에러 응답 표준화(4xx/5xx)
  - Order-Lot OpenAPI 계약 고정
- Out:
  - 인쇄/출력 기능
  - 배치 정산/통계
  - Legacy UI 연동 전체 전환

## 변경 요약(코드/DB/계약/OpenAPI)
- 코드:
  - `services/order-lot/src/main/java/...` (Controller/Service/Repository/ExceptionHandler)
- DB:
  - `migration/flyway/V<NN>__order_lot_*.sql` (신규/인덱스/제약조건)
- 계약(OpenAPI):
  - `shared/contracts/order-lot.openapi.yaml`
- 기타:
  - gateway 라우팅 연동 필요 시 정책 파일 경로 명시

## 실행 방법(로컬 커맨드 포함)
```powershell
# 1) 모듈 테스트
.\gradlew.bat :services:order-lot:test

# 2) 서비스 로컬 기동
.\gradlew.bat :services:order-lot:bootRun

# 3) 게이트 실행
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate build
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate unit-integration-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate contract-test
$env:SCM_ENABLE_GATEWAY_E2E_SMOKE="1"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate smoke-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate migration-dry-run
```

## 게이트 결과 체크
| Gate | 결과(PASS/FAIL) | 실행 커맨드 | 증적 링크/파일 경로 |
|---|---|---|---|
| build | [ ] PASS [ ] FAIL | `ci-run-gate.ps1 -Gate build` | `<runbooks/evidence/.../gate-build.log>` |
| unit-integration-test | [ ] PASS [ ] FAIL | `ci-run-gate.ps1 -Gate unit-integration-test` | `<runbooks/evidence/.../gate-unit-integration.log>` |
| contract-test | [ ] PASS [ ] FAIL | `ci-run-gate.ps1 -Gate contract-test` | `<runbooks/evidence/.../gate-contract.log>` |
| smoke-test | [ ] PASS [ ] FAIL | `ci-run-gate.ps1 -Gate smoke-test` | `<runbooks/evidence/.../gate-smoke.log>` |
| migration-dry-run | [ ] PASS [ ] FAIL | `ci-run-gate.ps1 -Gate migration-dry-run` | `<runbooks/evidence/.../gate-migration-dry-run.log>` |

## 리스크/롤백
- 리스크:
  - Order-Lot 상태 전이 규칙 불일치로 업무 오류 발생
  - 대량 조회 시 인덱스 미비로 지연 증가
  - 트랜잭션 경계 누락으로 데이터 정합성 저하
- 롤백:
  - 코드 롤백: PR revert
  - DB 롤백: `scripts/restore-db.ps1`로 직전 백업 복원
  - 게이트 재확인 후 재배포

## DoD 체크(측정 기준 포함)
- [ ] Order 조회 API p95 `<= 350ms` (샘플 1,000건)
- [ ] Lot 할당 API p95 `<= 500ms` (샘플 500건)
- [ ] API 오류율 `<= 1.0%` (5분 윈도우)
- [ ] Order/Lot 정합성 mismatch `0건`
- [ ] contract mismatch `0건`
- [ ] 필수 게이트 pass율 `100%`

## QnA 반영 여부(doc/QnA_보고서.md)
- [ ] 반영 완료
- QnA 항목: `<Q번호>`
- 파일 경로: `doc/QnA_보고서.md`

---

## 서브태스크 체크리스트
- [ ] OpenAPI `order-lot.openapi.yaml` 엔드포인트/스키마 확정
- [ ] Order Controller/Service/Repository 구현
- [ ] Lot Controller/Service/Repository 구현
- [ ] 도메인 예외/에러코드 표준화
- [ ] DB 마이그레이션 SQL(V<NN>) 추가 및 dry-run 통과
- [ ] 단위/통합 테스트 작성 및 통과
- [ ] 성능 측정(p95/오류율) 결과 첨부
- [ ] 게이트 5종 로그 첨부 후 PR 본문 업데이트
