# 2026-03-05 종료까지 후속 진행 절차

## 1) SCM-228 머지/이슈 종료 확정

```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
gh pr checks 39
gh pr merge 39 --squash --delete-branch
gh issue close 38 --comment "Merged via PR #39"
gh pr view 39 --json state,mergedAt
gh issue view 38 --json state
```

체크포인트:
- PR #39 = `MERGED`
- Issue #38 = `CLOSED`

DoD:
- rollback health PASS 고정 코드가 기준 브랜치에 반영됨.

## 2) 기준 브랜치 동기화 + 종료 작업 브랜치 생성

```powershell
git checkout feature/to-be-dev-env-bootstrap
git pull --ff-only
git checkout -b feature/scm-229-phase4-signoff-close
```

체크포인트:
- 기준 브랜치 최신 동기화 완료.
- 종료 작업은 전용 브랜치에서 시작.

DoD:
- 종료 작업의 시작 기준선이 고정됨.

## 3) Signoff 문서에 SCM-228 증적 링크 반영

대상 파일:
- `runbooks/go-nogo-signoff.md`

반영 내용:
- `rollback health (auth/member/gateway=UP)` 지표 1행 추가
- `runbooks/evidence/SCM-228-.../rollback-health-summary.md` 링크 추가

체크포인트:
- Signoff 표에 rollback health 지표가 존재.

DoD:
- 롤백 지표 2개(`time<=20m`, `health all UP`) 모두 PASS 명시.

## 4) phase-4 미완료 항목 닫기(보안/테스트 리포트 실측화)

```powershell
New-Item -ItemType Directory -Force .\runbooks\evidence\SCM-229 | Out-Null
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate lint-static-analysis 2>&1 | Tee-Object .\runbooks\evidence\SCM-229\gate-lint-static-analysis.log
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate security-scan 2>&1 | Tee-Object .\runbooks\evidence\SCM-229\gate-security-scan.log
```

대상 파일:
- `runbooks/security-checklist.md`
- `runbooks/test-report.md`

체크포인트:
- 체크리스트 미체크 항목 제거
- 이슈/리스크 수치 기입

DoD:
- High 이상 미해결 0건
- 비밀정보 노출 패턴 0건
- 근거 링크 포함

## 5) progress 상태값 동기화

대상 파일:
- `doc/roadmap/progress.json`

반영 내용:
- phase-5: `Go/No-Go checklist signed=true`
- phase-4: 보안/테스트 보고서 완료 후 `completed`
- `updated_at` 갱신

체크포인트:
- `updated_at` 최신 시간으로 갱신됨.

DoD:
- 문서 상태와 실제 증적 상태 불일치 0건.

## 6) 최종 DoD 검증 배치 1회 재실행(무스킵)

```powershell
$ev=".\runbooks\evidence\SCM-229-final"; New-Item -ItemType Directory -Force $ev | Out-Null
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate build 2>&1 | Tee-Object "$ev\gate-build.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate unit-integration-test 2>&1 | Tee-Object "$ev\gate-unit-integration-test.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate contract-test 2>&1 | Tee-Object "$ev\gate-contract-test.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate lint-static-analysis 2>&1 | Tee-Object "$ev\gate-lint-static-analysis.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate security-scan 2>&1 | Tee-Object "$ev\gate-security-scan.log"
$env:SCM_ENABLE_GATEWAY_E2E_SMOKE="1"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate smoke-test 2>&1 | Tee-Object "$ev\gate-smoke-test.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate migration-dry-run 2>&1 | Tee-Object "$ev\gate-migration-dry-run.log"
```

체크포인트:
- 각 게이트 exit code 0
- 로그 내 `[FAIL]` 0건

DoD:
- `dev_plan 2.2` 조건 충족(7게이트 skip 없이 PASS).

## 7) 종료 PR 생성/머지

```powershell
git add runbooks/go-nogo-signoff.md runbooks/security-checklist.md runbooks/test-report.md doc/roadmap/progress.json doc/QnA_보고서.md
git commit -m "docs(scm-229): close phase-4/5 evidence sync and final DoD gates"
git push -u origin feature/scm-229-phase4-signoff-close
gh pr create --base feature/to-be-dev-env-bootstrap --head feature/scm-229-phase4-signoff-close --title "docs(scm-229): finalize phase-4/5 closeout" --body "Final closeout sync for signoff/progress/security/test and 7-gate evidence."
```

체크포인트:
- 종료 PR 생성/머지 완료
- 이슈 연계/증적 코멘트 첨부 완료

DoD:
- 종료 기준 충족
- 워킹트리 clean 유지
