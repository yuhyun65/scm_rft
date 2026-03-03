# [SCM-213] Migration Mapping/Validation Report R1

## 배경/목표
- 도메인별 이관 정합성을 수치로 검증해 Big-Bang 전환의 데이터 리스크를 통제한다.
- R1 기준 리포트(건수/합계/샘플링/상태분포)를 작성하고 증적을 고정 경로에 저장한다.

## 범위(in/out)
- In:
  - 도메인별 매핑표 정리
  - 검증 SQL 실행 및 결과 수집
  - `migration/reports/` R1 리포트 작성
- Out:
  - 최종 컷오버 실행
  - 운영 데이터 정제 작업 전체

## 변경 요약(코드/DB/계약/OpenAPI)
- 코드:
  - `migration/verify/*` (필요 시 검증 스크립트 보강)
- DB:
  - `migration/flyway/V<NN>__*.sql` (누락 인덱스/키 보완 시)
- 계약(OpenAPI):
  - 변경 없음 (`N/A`)
- 리포트:
  - `migration/reports/R1-*.md`
  - `migration/reports/validation-*.md`

## 실행 방법(로컬 커맨드 포함)
```powershell
# 1) Dry-run (mismatch 발생 시 실패)
powershell -ExecutionPolicy Bypass -File .\migration\scripts\dry-run.ps1 -RunId "R1-<date>" -OutputDir "migration/reports" -FailOnMismatch

# 2) Validation 리포트 생성
powershell -ExecutionPolicy Bypass -File .\migration\verify\validate-migration.ps1 -ConfigPath "migration/verify/config.sample.json" -OutputDir "migration/reports" -FailOnMismatch

# 3) 필수 게이트
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
  - 매핑 누락으로 도메인별 count mismatch 발생
  - 상태값 표준화 불일치로 분포 편차 확대
  - 샘플 검증 기준 미흡으로 숨은 오류 잔존
- 롤백:
  - 검증 config/SQL 이전 버전 복원
  - mismatch 원인 도메인 분리 후 재실행
  - 실패 리포트 유지 + No-Go 판정

## DoD 체크(측정 기준 포함)
- [ ] count mismatch `0건`
- [ ] sum delta `<= 0.1%`
- [ ] sample mismatch `0/200`
- [ ] status distribution delta `<= 1.0%p`
- [ ] validation report `FailedChecks: 0`
- [ ] 필수 게이트 pass율 `100%`

## QnA 반영 여부(doc/QnA_보고서.md)
- [ ] 반영 완료
- QnA 항목: `<Q번호>`
- 파일 경로: `doc/QnA_보고서.md`

---

## 서브태스크 체크리스트
- [ ] 도메인별 매핑표 업데이트(auth/member/file/inventory/report/order-lot/board/quality-doc)
- [ ] 검증 SQL(건수/합계/샘플/상태분포) 실행 스크립트 준비
- [ ] dry-run 실행 및 상태 파일 저장
- [ ] validation 리포트 생성 및 실패항목 0건 확인
- [ ] mismatch 발생 시 원인 분류(count/sum/sample/state)
- [ ] 보정 SQL/인덱스 반영 후 재검증
- [ ] R1 리포트 문서화 및 증적 경로 정리
- [ ] 게이트 5종 결과 첨부
