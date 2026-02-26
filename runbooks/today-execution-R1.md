# Today Execution R1 (2026-02-26)

## Fixed Context
- Base branch: `feature/to-be-dev-env-bootstrap`
- Principle: `1 Issue = 1 PR = 1 dedicated branch`
- Mandatory gates: `build`, `unit-integration-test`, `contract-test`, `smoke-test`, `migration-dry-run`
- Artifact paths:
  - Contracts: `shared/contracts/`
  - Migration reports: `migration/reports/`
  - Operations/Rehearsal: `runbooks/`
  - QnA: `doc/QnA_보고서.md`
- Today scope: `SCM-210~214` (`SCM-210 Order-Lot P0` first)

## 0) One-time Setup (09:00 이전 1회)
```powershell
$RunDate = Get-Date -Format "yyyy-MM-dd"
$RunId = "R1-$RunDate"
$EvidenceDir = "runbooks/evidence/$RunDate"
New-Item -ItemType Directory -Force $EvidenceDir | Out-Null
```

## 1) 09:00-09:30
- Track A (Dev): 기준 브랜치 동기화 + 도구/포트 점검
- Track B (Codex): 산출물 디렉터리 생성 + 게이트 로그 파일 경로 고정
- Checkpoint:
  - `git status` clean
  - `check-prereqs` mismatch `0`
  - Docker daemon `UP`
  - 포트 충돌 `0건` (`8081,8082,18080,11433,35672`)
- Commands:
```powershell
git fetch --all --prune
git switch feature/to-be-dev-env-bootstrap
git pull --ff-only
powershell -ExecutionPolicy Bypass -File .\scripts\check-prereqs.ps1 -Strict 2>&1 | Tee-Object "$EvidenceDir\check-prereqs.log"
docker info | Out-Null
Get-NetTCPConnection -State Listen | Where-Object { $_.LocalPort -in 8081,8082,18080,11433,35672 } | Sort-Object LocalPort | Tee-Object "$EvidenceDir\ports.log"
```
- Stop condition:
  - `check-prereqs` 실패
  - Docker daemon down
  - 포트 충돌 1건 이상이 10분 내 해소되지 않음

## 2) 09:30-10:00
- Track A (Dev): SCM-210~214 이슈 생성
- Track B (Codex): 이슈-브랜치 매핑 표 작성
- Checkpoint:
  - Open issue 정확히 `5건` 생성 (`SCM-210~214`)
  - 각 이슈 제목 prefix `[SCM-xxx]` 일치율 `100%`
- Commands:
```powershell
gh issue create --title "[SCM-210] Order-Lot P0 API MVP" --body "Order-Lot P0 API MVP implementation with measurable DoD"
gh issue create --title "[SCM-211] Board + Quality-Doc MVP" --body "Board and Quality-Doc MVP APIs with measurable DoD"
gh issue create --title "[SCM-212] Gateway policy expansion (all domains)" --body "Gateway routing/policy across auth/member/file/inventory/report/order-lot/board/quality-doc"
gh issue create --title "[SCM-213] Migration mapping/validation report R1" --body "Domain validation SQL and evidence"
gh issue create --title "[SCM-214] Rehearsal R1 + Go/No-Go update" --body "90-minute rehearsal and Go/No-Go thresholds"
gh issue list --state open --limit 30 | Tee-Object "$EvidenceDir\issue-list.log"
```
- Stop condition:
  - 이슈 생성 실패 1건 이상
  - 중복/오표기 이슈 발생 후 10분 내 정리 실패

## 3) 10:00-11:00
- Track A (Dev): `SCM-210` 전용 브랜치 생성 + Order-Lot 계약 고정
- Track B (Codex): `SCM-213` 검증 SQL 템플릿 초안 생성
- Checkpoint:
  - 브랜치 `feature/scm-210-order-lot-p0-mvp` 생성
  - `shared/contracts/order-lot.openapi.yaml` 최소 엔드포인트 정의 `100%`
  - 필수 엔드포인트: `order create/read`, `lot assign/read`
- Commands:
```powershell
git switch -c feature/scm-210-order-lot-p0-mvp
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate contract-test 2>&1 | Tee-Object "$EvidenceDir\scm210-contract-test.log"
```
- Stop condition:
  - contract-test 실패
  - 계약 파일에서 `openapi`, `paths` 누락 1건 이상

## 4) 11:00-12:00
- Track A (Dev): `SCM-210` API 골격 구현(Controller/Service/Repository)
- Track B (Codex): Order-Lot 성능 측정 스크립트 초안 + 체크리스트 고정
- Checkpoint:
  - `:services:order-lot:test` 통과
  - API 기본 에러코드(400/401/404/500) 매핑 `100%`
- Commands:
```powershell
.\gradlew.bat :services:order-lot:test 2>&1 | Tee-Object "$EvidenceDir\scm210-order-lot-test.log"
```
- Stop condition:
  - 테스트 실패 1건 이상
  - 핵심 API(주문/LOT) 미구현 상태로 12:00 도달

## 5) 13:00-14:00
- Track A (Dev): `SCM-211` 전용 브랜치 생성 + Board/Quality-Doc 계약 고정
- Track B (Codex): Gateway 정책 매트릭스 작성(`SCM-212` 입력물)
- Checkpoint:
  - 브랜치 `feature/scm-211-board-qualitydoc-mvp` 생성
  - `board.openapi.yaml`, `quality-doc.openapi.yaml` contract-test 통과
- Commands:
```powershell
git switch feature/to-be-dev-env-bootstrap
git switch -c feature/scm-211-board-qualitydoc-mvp
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate contract-test 2>&1 | Tee-Object "$EvidenceDir\scm211-contract-test.log"
```
- Stop condition:
  - 계약 테스트 실패
  - 14:00 시점에도 엔드포인트 정의율 100% 미달

## 6) 14:00-15:00
- Track A (Dev): `SCM-212` 전용 브랜치 생성 + gateway 라우팅/정책 반영
- Track B (Codex): 도메인별 timeout/retry/circuit-breaker/rate-limit 수치 확정
- Checkpoint:
  - 브랜치 `feature/scm-212-gateway-policy-all-domains` 생성
  - 도메인 라우트 등록률 `100%` (8개 도메인)
- Commands:
```powershell
git switch feature/to-be-dev-env-bootstrap
git switch -c feature/scm-212-gateway-policy-all-domains
$env:GATEWAY_POLICY_PATH="infra/gateway/policies/cutover-isolation.yaml"
.\gradlew.bat :services:gateway:test 2>&1 | Tee-Object "$EvidenceDir\scm212-gateway-test.log"
```
- Stop condition:
  - gateway 라우트 누락 1개 이상
  - auth verify 연동 실패(401/200 판정 오류) 1건 이상

## 7) 15:00-16:00
- Track A (Dev): `SCM-213` 전용 브랜치 생성 + dry-run/정합성 검증
- Track B (Codex): R1 검증 리포트 파일 생성/정리
- Checkpoint:
  - `FailedChecks: 0`
  - count mismatch `0건`
  - sum delta `<= 0.1%`
- Commands:
```powershell
git switch feature/to-be-dev-env-bootstrap
git switch -c feature/scm-213-migration-validation-r1
powershell -ExecutionPolicy Bypass -File .\migration\scripts\dry-run.ps1 -RunId "R1-20260226" -OutputDir "migration/reports" -FailOnMismatch 2>&1 | Tee-Object "$EvidenceDir\scm213-dry-run.log"
powershell -ExecutionPolicy Bypass -File .\migration\verify\validate-migration.ps1 -ConfigPath "migration/verify/config.sample.json" -OutputDir "migration/reports" -FailOnMismatch 2>&1 | Tee-Object "$EvidenceDir\scm213-validate.log"
```
- Stop condition:
  - `FailedChecks > 0`
  - dry-run/validation exit code non-zero

## 8) 16:00-17:00
- Track A (Dev): `SCM-210` 브랜치 기준 필수 게이트 5개 일괄 실행
- Track B (Codex): PR 증적 패키지 구성
- Checkpoint:
  - 5개 게이트 pass `100%`
  - smoke skip `0건`
- Commands:
```powershell
git switch feature/scm-210-order-lot-p0-mvp
$env:SCM_ENABLE_GATEWAY_E2E_SMOKE="1"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate build 2>&1 | Tee-Object "$EvidenceDir\gate-build.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate unit-integration-test 2>&1 | Tee-Object "$EvidenceDir\gate-unit-integration.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate contract-test 2>&1 | Tee-Object "$EvidenceDir\gate-contract.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate smoke-test 2>&1 | Tee-Object "$EvidenceDir\gate-smoke.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate migration-dry-run 2>&1 | Tee-Object "$EvidenceDir\gate-migration-dry-run.log"
```
- Stop condition:
  - 게이트 실패 1건 이상
  - smoke 로그에 `[SKIP]` 1건 이상

## 9) 17:00-18:00
- Track A (Dev): `SCM-214` 전용 브랜치 생성 + 리허설 R1 실행
- Track B (Codex): Go/No-Go 판정표 작성/업데이트
- Checkpoint:
  - 리허설 총 소요시간 `<= 90분`
  - Critical 실패 `0건`
  - 데이터 mismatch `0건`
- Commands:
```powershell
git switch feature/to-be-dev-env-bootstrap
git switch -c feature/scm-214-rehearsal-r1-signoff
powershell -ExecutionPolicy Bypass -File .\scripts\rehearsal-run.ps1 -FailOnMismatch 2>&1 | Tee-Object "$EvidenceDir\scm214-rehearsal.log"
```
- Stop condition:
  - 리허설 실패
  - 롤백 필요 상태에서 20분 내 복구 실패

## End-of-day Output Checklist
- `runbooks/evidence/<date>/gate-*.log` 5개
- `migration/reports/validation-*.md` 최신 1개 이상
- `shared/contracts/*.openapi.yaml` 변경분 커밋 반영
- `doc/QnA_보고서.md` 당일 QnA 반영
