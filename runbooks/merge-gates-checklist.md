# Merge Gates Checklist

## 0) Evidence Path 고정
```powershell
$IssueKey = "SCM-210"   # 예: SCM-211, SCM-212 ...
$RunTs = Get-Date -Format "yyyyMMdd-HHmmss"
$EvDir = "runbooks/evidence/$IssueKey-$RunTs"
New-Item -ItemType Directory -Force $EvDir | Out-Null
```

## 0-1) PR 체크 리포트 공백 대응 (필수)
- `gh pr checks <PR번호>` 결과가 비어 있으면(`no checks reported`) **머지 금지**.
- 아래 5개 로컬 게이트 로그를 PR 코멘트에 반드시 남긴 뒤에만 머지:
  - `gate-build.log`
  - `gate-unit-integration.log`
  - `gate-contract.log`
  - `gate-smoke.log`
  - `gate-migration-dry-run.log`

```powershell
$PrNo = 0
gh pr checks $PrNo | Tee-Object "$EvDir\gh-pr-checks.txt"
```

## 0-2) 순차 머지(rebase) 규칙 (필수)
- 순서 의존 PR은 **앞 PR 머지 직후, 다음 PR 머지 직전에 rebase** 한다.
- 예: `#16 -> #17 -> #18`이면 `#17/#18`은 merge 직전 rebase + force-push가 필수.

```powershell
git fetch origin
git rebase origin/feature/to-be-dev-env-bootstrap
git push --force-with-lease
```

## 1) 필수 게이트 실행/판정/즉시조치

| Gate | 실행 커맨드 | 성공 판정 | 실패 시 즉시 조치 |
|---|---|---|---|
| build | `powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate build 2>&1 | Tee-Object "$EvDir\gate-build.log"` | exit code `0`, 로그 내 `[FAIL]` `0건` | 1) 머지 중단 2) `gate-build.log` 마지막 80줄 확인 3) 실패 모듈 단위 재실행(`.\gradlew.bat :<module>:build -x test`) 4) 수정 후 build 재실행 |
| unit-integration-test | `powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate unit-integration-test 2>&1 | Tee-Object "$EvDir\gate-unit-integration.log"` | exit code `0`, 테스트 실패 `0건`, 오류 `0건` | 1) 머지 중단 2) 실패 테스트 단독 재현(`.\gradlew.bat test --tests "*ClassName*"`) 3) flaky 여부 확인 4) 수정 후 전체 test 재실행 |
| contract-test | `powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate contract-test 2>&1 | Tee-Object "$EvDir\gate-contract.log"` | exit code `0`, `openapi: 3.x`/`paths` 누락 `0건` | 1) 머지 중단 2) 누락 파일 즉시 수정 3) `shared/contracts/*.openapi.yaml` diff 재검토 4) contract-test 재실행 |
| smoke-test | `$env:SCM_ENABLE_GATEWAY_E2E_SMOKE="1"; powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate smoke-test 2>&1 | Tee-Object "$EvDir\gate-smoke.log"` | exit code `0`, smoke `[FAIL]` `0건`, smoke `[SKIP]` `0건` | 1) 머지 중단 2) auth/member/gateway health 확인 3) 포트/DB/env 재점검 4) `scripts\smoke-gateway-auth-member-e2e.ps1` 단독 재실행 |
| migration-dry-run | `powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate migration-dry-run 2>&1 | Tee-Object "$EvDir\gate-migration-dry-run.log"` | exit code `0`, `migration/reports/validation-*.md` 최신 파일의 `FailedChecks: 0` | 1) 머지 중단 2) mismatch 유형(count/sum/sample/file) 분류 3) SQL/매핑 수정 4) dry-run + validate 재실행 |

## 2) 게이트 일괄 실행 (복붙용)
```powershell
$IssueKey = "SCM-210"
$RunTs = Get-Date -Format "yyyyMMdd-HHmmss"
$EvDir = "runbooks/evidence/$IssueKey-$RunTs"
New-Item -ItemType Directory -Force $EvDir | Out-Null

powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate build 2>&1 | Tee-Object "$EvDir\gate-build.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate unit-integration-test 2>&1 | Tee-Object "$EvDir\gate-unit-integration.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate contract-test 2>&1 | Tee-Object "$EvDir\gate-contract.log"
$env:SCM_ENABLE_GATEWAY_E2E_SMOKE="1"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate smoke-test 2>&1 | Tee-Object "$EvDir\gate-smoke.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate migration-dry-run 2>&1 | Tee-Object "$EvDir\gate-migration-dry-run.log"
```

## 3) PR 본문 첨부 증적 목록(필수)

| 구분 | 파일/로그 | 저장 위치 |
|---|---|---|
| Gate log | `gate-build.log` | `runbooks/evidence/<ISSUE>-<TS>/` |
| Gate log | `gate-unit-integration.log` | `runbooks/evidence/<ISSUE>-<TS>/` |
| Gate log | `gate-contract.log` | `runbooks/evidence/<ISSUE>-<TS>/` |
| Gate log | `gate-smoke.log` | `runbooks/evidence/<ISSUE>-<TS>/` |
| Gate log | `gate-migration-dry-run.log` | `runbooks/evidence/<ISSUE>-<TS>/` |
| Migration report | `validation-*.md` 최신 1개 | `migration/reports/` |
| Migration state | `dryrun-*.state.json` 또는 `<RunId>.state.json` | `migration/reports/` |
| Contract diff | `contracts-diff.txt` | `runbooks/evidence/<ISSUE>-<TS>/` |
| PR checks text | `gh-pr-checks.txt` | `runbooks/evidence/<ISSUE>-<TS>/` |
| Smoke detail | `smoke-gateway-auth-member-e2e.log` (선택) | `runbooks/evidence/<ISSUE>-<TS>/` |
| Screenshot | `gh-checks.png` (선택) | `runbooks/evidence/<ISSUE>-<TS>/` |

## 4) 증적 생성 커맨드
```powershell
# contract diff
$contracts = git diff --name-only HEAD~1 HEAD -- shared/contracts | Out-String
$contracts | Set-Content -Encoding UTF8 "$EvDir\contracts-diff.txt"

# PR checks export
$PrNo = 0  # 실제 PR 번호로 교체
if ($PrNo -gt 0) {
  gh pr checks $PrNo | Tee-Object "$EvDir\gh-pr-checks.txt"
}

# smoke 단독 로그 수집(필요 시)
powershell -ExecutionPolicy Bypass -File .\scripts\smoke-gateway-auth-member-e2e.ps1 2>&1 | Tee-Object "$EvDir\smoke-gateway-auth-member-e2e.log"
```

## 5) PR 본문 붙여넣기 템플릿
```markdown
## Mandatory Gates
- [x] build (log: `runbooks/evidence/<ISSUE>-<TS>/gate-build.log`)
- [x] unit-integration-test (log: `runbooks/evidence/<ISSUE>-<TS>/gate-unit-integration.log`)
- [x] contract-test (log: `runbooks/evidence/<ISSUE>-<TS>/gate-contract.log`)
- [x] smoke-test (log: `runbooks/evidence/<ISSUE>-<TS>/gate-smoke.log`)
- [x] migration-dry-run (log: `runbooks/evidence/<ISSUE>-<TS>/gate-migration-dry-run.log`)

## Evidence
- migration report: `migration/reports/validation-<TS>.md` (`FailedChecks: 0`)
- contract diff: `runbooks/evidence/<ISSUE>-<TS>/contracts-diff.txt`
- pr checks: `runbooks/evidence/<ISSUE>-<TS>/gh-pr-checks.txt`
```

## 6) Merge Block Rules
- 아래 조건 중 하나라도 참이면 머지 금지:
  - 필수 게이트 pass율 `100%` 미달
  - smoke `[SKIP]` `1건` 이상
  - migration `FailedChecks > 0`
  - PR 증적 파일 누락 `1개` 이상
  - `gh pr checks` 결과가 비어 있는데 로컬 5게이트 증적 코멘트가 없는 경우
  - 순차 머지 대상 PR에서 merge 직전 rebase 증적(로그/코멘트)이 없는 경우
