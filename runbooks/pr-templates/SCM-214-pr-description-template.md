# [SCM-214] Rehearsal R1 + Go/No-Go Draft Update

## 배경/목표
- Big-Bang 전환 전 리허설 R1을 수행해 절차/성능/정합성 기준을 수치로 검증한다.
- Go/No-Go 초안을 임계치 기반으로 업데이트한다.

## 범위(in/out)
- In:
  - Prep → Cutover → Validation → Rollback(optional) → Signoff 절차 실행
  - 리허설 로그/증적 수집
  - Go/No-Go 판정표 업데이트
- Out:
  - 실제 운영 컷오버
  - 운영 조직 승인 최종 결재

## 변경 요약(코드/DB/계약/OpenAPI)
- 코드:
  - `scripts/rehearsal-run.ps1` (필요 시 보강)
  - `runbooks/rehearsal-R1-runbook.md`
  - `runbooks/go-nogo-signoff.md`
- DB:
  - 백업/복원 실행 로그 (`scripts/backup-db.ps1`, `scripts/restore-db.ps1`)
- 계약(OpenAPI):
  - 변경 없음 (`N/A`)
- 리포트:
  - `migration/reports/validation-*.md`
  - `runbooks/evidence/<RunId>/*`

## 실행 방법(로컬 커맨드 포함)
```powershell
# 1) 리허설 시퀀스 실행
powershell -ExecutionPolicy Bypass -File .\scripts\rehearsal-run.ps1 -FailOnMismatch

# 2) E2E smoke 개별 실행(필요 시)
powershell -ExecutionPolicy Bypass -File .\scripts\smoke-gateway-auth-member-e2e.ps1

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
  - 리허설 90분 초과로 컷오버 절차 신뢰성 저하
  - 검증 통과 기준 누락으로 Go/No-Go 오판
  - 롤백 실효성 부족
- 롤백:
  - DB 즉시 복원: `scripts/restore-db.ps1`
  - gateway emergency-stop 활성화
  - No-Go 선언 후 차수 재실행

## DoD 체크(측정 기준 포함)
- [ ] 리허설 총 소요시간 `<= 90분`
- [ ] Cutover 단계 누락 `0건`
- [ ] API 오류율 `<= 1.0%`
- [ ] 핵심 API p95 latency `<= 350ms`
- [ ] 데이터 정합성 mismatch `0건`
- [ ] 롤백 필요 시 복구시간 `<= 20분`
- [ ] 필수 게이트 pass율 `100%`

## QnA 반영 여부(doc/QnA_보고서.md)
- [ ] 반영 완료
- QnA 항목: `<Q번호>`
- 파일 경로: `doc/QnA_보고서.md`

---

## 서브태스크 체크리스트
- [ ] 리허설 실행 변수/증적 경로 초기화
- [ ] Prep 단계(환경/스테이징/백업) 완료
- [ ] Cutover 단계(auth/member/gateway 기동) 완료
- [ ] Validation 단계(smoke + migration report) 완료
- [ ] Rollback 시나리오(선택) 실행 및 시간 측정
- [ ] Go/No-Go 임계치 판정표 업데이트
- [ ] 리허설 로그/증적 경로 정리
- [ ] 게이트 5종 결과 첨부
- [ ] QnA 보고서 반영
