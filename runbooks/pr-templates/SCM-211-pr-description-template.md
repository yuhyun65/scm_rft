# [SCM-211] Board + Quality-Doc MVP

## 배경/목표
- 게시판/품질문서 도메인을 분리 API로 구현해 레거시 화면-프로시저 강결합을 해소한다.
- Board 조회/등록, Quality-Doc 조회/ACK를 MVP로 제공한다.

## 범위(in/out)
- In:
  - Board 목록/상세/등록 API
  - Quality-Doc 목록/상세/ACK API
  - 첨부 메타 연계(필요 시 file 서비스)
  - 도메인별 OpenAPI 계약 확정
- Out:
  - 문서 뷰어/인쇄 UI
  - 고급 검색/통계 리포트
  - 배치 알림 처리

## 변경 요약(코드/DB/계약/OpenAPI)
- 코드:
  - `services/board/src/main/java/...`
  - `services/quality-doc/src/main/java/...`
- DB:
  - `migration/flyway/V<NN>__board_quality_doc_*.sql`
- 계약(OpenAPI):
  - `shared/contracts/board.openapi.yaml`
  - `shared/contracts/quality-doc.openapi.yaml`
- 기타:
  - gateway 라우트(`/api/board/**`, `/api/quality-doc/**`) 반영 여부 기록

## 실행 방법(로컬 커맨드 포함)
```powershell
# 1) 모듈 테스트
.\gradlew.bat :services:board:test :services:quality-doc:test

# 2) 서비스 로컬 기동
.\gradlew.bat :services:board:bootRun
.\gradlew.bat :services:quality-doc:bootRun

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
  - 게시글/문서 상태값 매핑 불일치
  - ACK 중복 처리로 데이터 왜곡
  - 첨부 메타 연계 실패로 조회 누락
- 롤백:
  - 코드 롤백: PR revert
  - DB 롤백: `scripts/restore-db.ps1`
  - Gateway route disable 후 서비스 격리

## DoD 체크(측정 기준 포함)
- [ ] Board 목록/상세 API p95 `<= 300ms`
- [ ] Quality-Doc ACK API p95 `<= 500ms`
- [ ] API 오류율 `<= 1.0%`
- [ ] ACK 중복 처리 오류 `0건`
- [ ] contract mismatch `0건`
- [ ] 필수 게이트 pass율 `100%`

## QnA 반영 여부(doc/QnA_보고서.md)
- [ ] 반영 완료
- QnA 항목: `<Q번호>`
- 파일 경로: `doc/QnA_보고서.md`

---

## 서브태스크 체크리스트
- [ ] `board.openapi.yaml` 계약 확정
- [ ] `quality-doc.openapi.yaml` 계약 확정
- [ ] Board API(목록/상세/등록) 구현
- [ ] Quality-Doc API(목록/상세/ACK) 구현
- [ ] DB 마이그레이션 SQL(V<NN>) 추가 및 dry-run 통과
- [ ] 도메인 테스트(단위/통합) 통과
- [ ] gateway 경로/정책 반영 확인
- [ ] 게이트 5종 증적 첨부 및 PR 본문 업데이트
