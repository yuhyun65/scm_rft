# [SCM-212] Gateway Routing/Policy Expansion (All Domains)

## 배경/목표
- Gateway 정책을 전체 도메인(auth/member/file/inventory/report/order-lot/board/quality-doc)으로 확장한다.
- 도메인별 timeout/retry/circuit-breaker/rate-limit 기본값/예외값을 적용해 운영 안정성을 확보한다.

## 범위(in/out)
- In:
  - 8개 도메인 라우팅 추가/정리
  - 인증 필터 및 verify 연동 정책 고정
  - 도메인별 정책 override 반영(order-lot 예외 포함)
- Out:
  - 외부 API Gateway 제품 교체
  - 전면 트래픽 스위칭 자동화

## 변경 요약(코드/DB/계약/OpenAPI)
- 코드:
  - `services/gateway/src/main/java/...` (route/filter/policy loader)
- DB:
  - 변경 없음 (`N/A`)
- 계약(OpenAPI):
  - 라우팅 대상 계약 참조:
    - `shared/contracts/auth.openapi.yaml`
    - `shared/contracts/member.openapi.yaml`
    - `shared/contracts/file.openapi.yaml`
    - `shared/contracts/inventory.openapi.yaml`
    - `shared/contracts/report.openapi.yaml`
    - `shared/contracts/order-lot.openapi.yaml`
    - `shared/contracts/board.openapi.yaml`
    - `shared/contracts/quality-doc.openapi.yaml`
- 정책 파일:
  - `infra/gateway/policies/cutover-isolation.yaml`
  - `infra/gateway/policies/local-auth-member-e2e.yaml` (로컬 E2E)

## 실행 방법(로컬 커맨드 포함)
```powershell
# 1) gateway 테스트
.\gradlew.bat :services:gateway:test

# 2) gateway 로컬 기동(정책 파일 지정)
$env:GATEWAY_POLICY_PATH="infra/gateway/policies/cutover-isolation.yaml"
.\gradlew.bat :services:gateway:bootRun

# 3) 필수 smoke
$env:SCM_ENABLE_GATEWAY_E2E_SMOKE="1"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate smoke-test

# 4) 전체 게이트
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate build
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate unit-integration-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate contract-test
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
  - 정책 오적용으로 401/503 오탐
  - retry/cb 설정 과대/과소로 장애 전파
  - rate-limit 임계치 부정확으로 정상 트래픽 차단
- 롤백:
  - 정책 파일 이전 버전 복원
  - `GATEWAY_EMERGENCY_STOP_ENABLED=true`로 트래픽 보호
  - PR revert 후 gateway 재기동

## DoD 체크(측정 기준 포함)
- [ ] 8개 도메인 라우트 등록률 `100%`
- [ ] 보호 API 무토큰 호출 401 검증 성공률 `100%`
- [ ] gateway 추가 오버헤드 p95 `<= 30ms`
- [ ] order-lot 정책 예외값 적용 검증 `100%`
- [ ] 정책 파싱/적용 오류 `0건`
- [ ] 필수 게이트 pass율 `100%`

## QnA 반영 여부(doc/QnA_보고서.md)
- [ ] 반영 완료
- QnA 항목: `<Q번호>`
- 파일 경로: `doc/QnA_보고서.md`

---

## 서브태스크 체크리스트
- [ ] 도메인별 라우트 8개 정의/검증
- [ ] timeout/retry/circuit-breaker/rate-limit 기본값 설정
- [ ] order-lot 예외 정책값 반영
- [ ] 인증 verify 연동(실패 시 401) 검증
- [ ] emergency-stop 동작 검증(503)
- [ ] gateway 테스트/스모크 테스트 통과
- [ ] 정책 파일 문서화(runbooks 반영)
- [ ] 게이트 5종 로그 첨부 및 PR 본문 업데이트
