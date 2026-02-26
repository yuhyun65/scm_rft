# Rehearsal R1 Runbook (90-minute Target)

## Fixed Scope
- Scope: `SCM-210~214`
- Priority: `Order-Lot P0`
- Base branch: `feature/to-be-dev-env-bootstrap`
- Mandatory gates before signoff: `build`, `unit-integration-test`, `contract-test`, `smoke-test`, `migration-dry-run`

## 0) Run Variables
```powershell
$RunId = "R1-$(Get-Date -Format yyyyMMdd-HHmmss)"
$EvDir = "runbooks/evidence/$RunId"
New-Item -ItemType Directory -Force $EvDir | Out-Null
```

## 1) Prep (T+00 ~ T+15, 목표 15분)

| 항목 | 담당 | 입력물 | 산출물 | 목표 시간 | 중단 조건 |
|---|---|---|---|---:|---|
| 환경 점검 | Dev | `toolchain.lock.json`, `.env.staging` | `prep-check-prereqs.log` | 5분 | `check-prereqs -Strict` 실패 |
| 스테이징 기동 | Dev | Docker daemon `UP` | `prep-staging-up.log` | 5분 | `staging-up.ps1` 실패 |
| DB 백업 | Dev | `MSSQL_SA_PASSWORD` | `prep-backup.log`, `.bak` 파일 | 5분 | 백업 파일 생성 실패 |

Commands:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check-prereqs.ps1 -Strict 2>&1 | Tee-Object "$EvDir\prep-check-prereqs.log"
powershell -ExecutionPolicy Bypass -File .\scripts\staging-up.ps1 2>&1 | Tee-Object "$EvDir\prep-staging-up.log"
powershell -ExecutionPolicy Bypass -File .\scripts\backup-db.ps1 -Database "MES_HI" -Staging 2>&1 | Tee-Object "$EvDir\prep-backup.log"
```

## 2) Cutover (T+15 ~ T+35, 목표 20분)

| 항목 | 담당 | 입력물 | 산출물 | 목표 시간 | 중단 조건 |
|---|---|---|---|---:|---|
| Auth/Member SQL 모드 기동 | Dev | DB 접속 env | `cutover-auth.log`, `cutover-member.log` | 10분 | health `UP` 실패 |
| Gateway 정책 기동 | Dev | `infra/gateway/policies/local-auth-member-e2e.yaml` | `cutover-gateway.log` | 10분 | `/actuator/health` 실패 |

Commands (각각 별도 터미널):
```powershell
# Terminal A (auth)
$env:SCM_DB_URL="jdbc:sqlserver://localhost:1433;databaseName=MES_HI;encrypt=true;trustServerCertificate=true"
$env:SCM_DB_USER="sa"
$env:SCM_DB_PASSWORD="<MSSQL_SA_PASSWORD>"
$env:SCM_DB_DRIVER="com.microsoft.sqlserver.jdbc.SQLServerDriver"
$env:SCM_AUTH_JWT_SECRET="<32+ chars>"
.\gradlew.bat :services:auth:bootRun 2>&1 | Tee-Object "$EvDir\cutover-auth.log"

# Terminal B (member)
$env:SCM_DB_URL="jdbc:sqlserver://localhost:1433;databaseName=MES_HI;encrypt=true;trustServerCertificate=true"
$env:SCM_DB_USER="sa"
$env:SCM_DB_PASSWORD="<MSSQL_SA_PASSWORD>"
$env:SCM_DB_DRIVER="com.microsoft.sqlserver.jdbc.SQLServerDriver"
.\gradlew.bat :services:member:bootRun 2>&1 | Tee-Object "$EvDir\cutover-member.log"

# Terminal C (gateway)
$env:GATEWAY_POLICY_PATH="infra/gateway/policies/local-auth-member-e2e.yaml"
.\gradlew.bat :services:gateway:bootRun 2>&1 | Tee-Object "$EvDir\cutover-gateway.log"
```

Health check:
```powershell
Invoke-RestMethod http://localhost:8081/actuator/health | Tee-Object "$EvDir\health-auth.log"
Invoke-RestMethod http://localhost:8082/actuator/health | Tee-Object "$EvDir\health-member.log"
Invoke-RestMethod http://localhost:18080/actuator/health | Tee-Object "$EvDir\health-gateway.log"
```

## 3) Validation (T+35 ~ T+60, 목표 25분)

| 항목 | 담당 | 입력물 | 산출물 | 목표 시간 | 중단 조건 |
|---|---|---|---|---:|---|
| Gateway E2E smoke | Dev | auth/member/gateway `UP` | `validation-smoke.log` | 10분 | smoke 실패 1건 이상 |
| Migration dry-run + validate | Dev | migration config | `validation-dry-run.log`, `validation-report.log`, `migration/reports/validation-*.md` | 10분 | `FailedChecks > 0` |
| 결과 집계 | Codex | 로그/리포트 | `validation-summary.md` | 5분 | 수치 누락 1건 이상 |

Commands:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\smoke-gateway-auth-member-e2e.ps1 2>&1 | Tee-Object "$EvDir\validation-smoke.log"
powershell -ExecutionPolicy Bypass -File .\migration\scripts\dry-run.ps1 -RunId $RunId -OutputDir "migration/reports" -FailOnMismatch 2>&1 | Tee-Object "$EvDir\validation-dry-run.log"
powershell -ExecutionPolicy Bypass -File .\migration\verify\validate-migration.ps1 -ConfigPath "migration/verify/config.sample.json" -OutputDir "migration/reports" -FailOnMismatch 2>&1 | Tee-Object "$EvDir\validation-report.log"
```

## 4) Rollback (optional, T+60 ~ T+80, 목표 20분)

실행 조건:
- 오류율 `> 1.0%` (5분 평균)
- p95 latency `> 500ms` (핵심 API)
- 데이터 mismatch `>= 1건`

| 항목 | 담당 | 입력물 | 산출물 | 목표 시간 | 중단 조건 |
|---|---|---|---|---:|---|
| 백업 파일 선택 | Dev | `migration/backups/staging/*.bak` | 선택 파일명 기록 | 3분 | 사용 가능 백업 없음 |
| DB 복구 | Dev | 백업 파일명 | `rollback-restore.log` | 12분 | restore 실패 |
| 서비스 재검증 | Dev/Codex | restore 완료 | `rollback-health.log` | 5분 | health `UP` 실패 |

Commands:
```powershell
# 최신 백업 파일 확인
Get-ChildItem .\migration\backups\staging\*.bak | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# 복구 실행 (<BACKUP_FILE> 교체)
powershell -ExecutionPolicy Bypass -File .\scripts\restore-db.ps1 -BackupFile "<BACKUP_FILE>" -Database "MES_HI" -Staging 2>&1 | Tee-Object "$EvDir\rollback-restore.log"

# 복구 후 health 재검증
Invoke-RestMethod http://localhost:8081/actuator/health | Tee-Object "$EvDir\rollback-health.log"
Invoke-RestMethod http://localhost:8082/actuator/health | Tee-Object -Append "$EvDir\rollback-health.log"
Invoke-RestMethod http://localhost:18080/actuator/health | Tee-Object -Append "$EvDir\rollback-health.log"
```

## 5) Signoff (T+80 ~ T+90, 목표 10분)

| 항목 | 담당 | 입력물 | 산출물 | 목표 시간 | 중단 조건 |
|---|---|---|---|---:|---|
| 수치 판정 | Codex | smoke/migration/gate 로그 | `runbooks/go-nogo-signoff.md` 업데이트 | 7분 | 임계치 충족 불가 |
| 최종 승인 | Dev | signoff 문서 | 승인 코멘트/결론 | 3분 | 필수 증적 누락 1건 이상 |

Commands:
```powershell
$env:SCM_ENABLE_GATEWAY_E2E_SMOKE="1"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate build 2>&1 | Tee-Object "$EvDir\signoff-gate-build.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate unit-integration-test 2>&1 | Tee-Object "$EvDir\signoff-gate-unit-integration.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate contract-test 2>&1 | Tee-Object "$EvDir\signoff-gate-contract.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate smoke-test 2>&1 | Tee-Object "$EvDir\signoff-gate-smoke.log"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate migration-dry-run 2>&1 | Tee-Object "$EvDir\signoff-gate-migration.log"
```

## Go/No-Go 판정 테이블 (임계치 고정)

| 지표 | 측정 방법 | Go 기준 | No-Go 기준 |
|---|---|---|---|
| API 오류율 | smoke + 게이트 로그(5분 평균) | `<= 1.0%` | `> 1.0%` |
| 핵심 API p95 latency | Order-Lot/Member API 측정 | `<= 350ms` | `> 500ms` |
| 데이터 오차율(count/sum/sample/state) | `migration/reports/validation-*.md` | count mismatch `0`, sum delta `<= 0.1%`, sample mismatch `0`, state delta `<= 1.0%p` | 기준 1개라도 초과 |
| smoke 결과 | `scripts/smoke-gateway-auth-member-e2e.ps1` | 실패 `0건` | 실패 `>= 1건` |
| 필수 게이트 | `ci-run-gate.ps1` 5종 | pass `100%` | fail `>= 1건` |
| 롤백 시간(필요 시) | restore 시작~health UP | `<= 20분` | `> 20분` |
| 증적 완결성 | EvDir + migration/reports + QnA | 누락 `0건` | 누락 `>= 1건` |

## Completion Outputs
- `runbooks/evidence/<RunId>/` 전체 로그
- `migration/reports/validation-*.md` 최신 리포트
- `runbooks/go-nogo-signoff.md` 판정 반영본
- `doc/QnA_보고서.md` 리허설 기록 반영
