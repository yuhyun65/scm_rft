# SCM-214 Go/No-Go Sign-off (R1)

## 1) 실행 메타
- RunId: `<R1-YYYYMMDD-HHMMSS-ENV>`
- 기준 브랜치: `feature/to-be-dev-env-bootstrap`
- 판정 대상: `SCM-210~214`
- 판정 시점: `<yyyy-MM-dd HH:mm:ss>`
- 증적 루트: `runbooks/evidence/<RunId>/`

## 2) 판정 입력물(필수)
- [ ] `runbooks/evidence/<RunId>/gate-build.log`
- [ ] `runbooks/evidence/<RunId>/gate-unit-integration.log`
- [ ] `runbooks/evidence/<RunId>/gate-contract.log`
- [ ] `runbooks/evidence/<RunId>/gate-smoke.log`
- [ ] `runbooks/evidence/<RunId>/gate-migration-dry-run.log`
- [ ] `migration/reports/validation-*.md` 최신 파일
- [ ] Gateway/서비스 로그, Prometheus 쿼리 결과, SQL 결과 스냅샷

## 3) 전역 Go/No-Go 지표

| 지표 | 측정 위치(로그/메트릭/SQL) | 샘플 커맨드/쿼리 | GO 임계치 | 임계치 초과 시 즉시 조치(런북 링크) | 에스컬레이션 트리거 |
|---|---|---|---|---|---|
| 5xx 오류율 | Prometheus (`http_server_requests_seconds_count`) | `Invoke-RestMethod "http://localhost:9090/api/v1/query?query=$([uri]::EscapeDataString('sum(rate(http_server_requests_seconds_count{uri=~"/api/.*",status=~"5.."}[5m]))/sum(rate(http_server_requests_seconds_count{uri=~"/api/.*"}[5m]))*100'))"` | `<= 0.5%` | 1) `GATEWAY_EMERGENCY_STOP_ENABLED=true` 2) 장애 도메인 route 제한 3) [rehearsal-R1-runbook](./rehearsal-R1-runbook.md), [rollback-playbook](./rollback-playbook.md) 실행 | 임계치 초과 10분 지속 또는 5분 내 상승 추세 |
| 4xx 오류율 | Prometheus (`status=4..`) + gateway 로그 | `Invoke-RestMethod "http://localhost:9090/api/v1/query?query=$([uri]::EscapeDataString('sum(rate(http_server_requests_seconds_count{uri=~"/api/.*",status=~"4.."}[5m]))/sum(rate(http_server_requests_seconds_count{uri=~"/api/.*"}[5m]))*100'))"` | `<= 8.0%` | 1) 인증/권한 정책 오탐 확인 2) 계약/입력검증 차이 수정 3) [gateway-routing-matrix](./gateway-routing-matrix.md), [merge-gates-checklist](./merge-gates-checklist.md) 재검증 | 임계치 초과 10분 지속 |
| p95 latency | Prometheus histogram | `Invoke-RestMethod "http://localhost:9090/api/v1/query?query=$([uri]::EscapeDataString('histogram_quantile(0.95,sum(rate(http_server_requests_seconds_bucket{uri=~"/api/.*"}[5m])) by (le))*1000'))"` | `<= 350ms` | 1) 고지연 도메인 rate-limit 하향 2) 쿼리/인덱스 확인 3) [today-execution-R1](./today-execution-R1.md) 성능 보강 절차 실행 | 임계치 초과 10분 지속 |
| p99 latency | Prometheus histogram | `Invoke-RestMethod "http://localhost:9090/api/v1/query?query=$([uri]::EscapeDataString('histogram_quantile(0.99,sum(rate(http_server_requests_seconds_bucket{uri=~"/api/.*"}[5m])) by (le))*1000'))"` | `<= 700ms` | 1) 급증 API 일시 차단/제한 2) 장애 도메인 격리 3) [rehearsal-R1-runbook](./rehearsal-R1-runbook.md) Validation 재수행 | 임계치 초과 10분 지속 |
| RabbitMQ 적체 | RabbitMQ Management API (`messages_ready`,`messages_unacknowledged`) | `$cred=New-Object PSCredential('guest',(ConvertTo-SecureString 'guest' -AsPlainText -Force));$q=Invoke-RestMethod -Uri 'http://localhost:15672/api/queues' -Credential $cred;($q|Measure-Object messages_ready -Sum).Sum;($q|Measure-Object messages_unacknowledged -Sum).Sum` | `ready <= 1000` AND `unacked <= 500` | 1) 소비자 상태 점검/재기동 2) 큐별 병목 제거 3) [today-execution-R1](./today-execution-R1.md) 운영 절차 실행 | 임계치 초과 10분 지속 또는 증가율 양수 10분 지속 |
| DB deadlock/timeout | SQL Server system_health XEvent + 앱 로그 | `sqlcmd -S localhost,1433 -U sa -P <PWD> -d master -Q "SELECT SUM(CASE WHEN object_name='xml_deadlock_report' THEN 1 ELSE 0 END) deadlock_10m, SUM(CASE WHEN object_name='error_reported' AND CONVERT(xml,event_data).value('(event/data[@name=\"error_number\"]/value)[1]','int')=1222 THEN 1 ELSE 0 END) timeout_10m FROM sys.fn_xe_file_target_read_file('system_health*.xel',NULL,NULL,NULL) WHERE timestamp_utc>=DATEADD(MINUTE,-10,SYSUTCDATETIME());"` | `deadlock=0` AND `timeout<=3/10분` | 1) 장기 트랜잭션 종료 2) 락 경합 SQL 우회/튜닝 3) [rollback-playbook](./rollback-playbook.md) 대기 | deadlock 1건 즉시 또는 timeout 임계치 10분 지속 |
| 데이터 정합성 오차율 | `migration/reports/validation-*.md` + 도메인 SQL 결과 | `$latest=Get-ChildItem migration/reports/validation-*.md|Sort LastWriteTime -Desc|Select -First 1;Get-Content $latest.FullName|Select-String 'TotalChecks|FailedChecks'` | `count mismatch=0`, `sum<=0.1%`, `sample mismatch=0/200`, `status<=1.0%p` | 1) 컷오버 중단 2) `migration/sql/r1-validation/*.sql` 재실행 3) [rehearsal-R1-runbook](./rehearsal-R1-runbook.md) Rollback 단계 수행 | 기준 1개라도 초과 시 즉시 |
| 롤백 시간 | restore 실행 로그 + 측정 | `(Measure-Command { powershell -ExecutionPolicy Bypass -File .\scripts\restore-db.ps1 -BackupFile '<BACKUP.bak>' -Database 'MES_HI' -Staging }).TotalMinutes` | `<= 20분` | 1) 즉시 복원 수행 2) 미완료 시 트래픽 차단 유지 3) [rollback-playbook](./rollback-playbook.md) 절차 고정 | 20분 초과 즉시 |
| 인증 실패율 | Prometheus(auth route 401/403) + auth/gateway 로그 | `Invoke-RestMethod "http://localhost:9090/api/v1/query?query=$([uri]::EscapeDataString('sum(rate(http_server_requests_seconds_count{uri=~"/api/auth/.*",status=~"401|403"}[5m]))/sum(rate(http_server_requests_seconds_count{uri=~"/api/auth/.*"}[5m]))*100'))"` | `<= 3.0%` | 1) 토큰 발급/검증 흐름 점검 2) 시크릿/만료 정책 확인 3) [gateway-routing-matrix](./gateway-routing-matrix.md) 및 auth 설정 재검증 | 임계치 초과 10분 지속 |

## 4) Order-Lot 전용(강화) 임계치

| 지표 (order-lot 전용) | 측정 위치 | 샘플 커맨드/쿼리 | GO 임계치(강화) | 임계치 초과 시 즉시 조치 | 에스컬레이션 트리거 |
|---|---|---|---|---|---|
| 5xx 오류율 | Prometheus (`uri=~"/api/order-lot/.*"`) | `Invoke-RestMethod "http://localhost:9090/api/v1/query?query=$([uri]::EscapeDataString('sum(rate(http_server_requests_seconds_count{uri=~"/api/order-lot/.*",status=~"5.."}[5m]))/sum(rate(http_server_requests_seconds_count{uri=~"/api/order-lot/.*"}[5m]))*100'))"` | `<= 0.2%` | 1) order-lot write 즉시 차단 2) read-only fallback 전환 3) [rehearsal-R1-runbook](./rehearsal-R1-runbook.md) Rollback 준비 | 5분 지속 |
| p95 latency | Prometheus (`order-lot`) | `Invoke-RestMethod "http://localhost:9090/api/v1/query?query=$([uri]::EscapeDataString('histogram_quantile(0.95,sum(rate(http_server_requests_seconds_bucket{uri=~"/api/order-lot/.*"}[5m])) by (le))*1000'))"` | `<= 250ms` | 1) 고비용 쿼리 제한 2) write 요청 감속 3) [gateway-routing-matrix](./gateway-routing-matrix.md) rate-limit 하향 적용 | 5분 지속 |
| p99 latency | Prometheus (`order-lot`) | `Invoke-RestMethod "http://localhost:9090/api/v1/query?query=$([uri]::EscapeDataString('histogram_quantile(0.99,sum(rate(http_server_requests_seconds_bucket{uri=~"/api/order-lot/.*"}[5m])) by (le))*1000'))"` | `<= 450ms` | 1) write 중단 2) read path만 유지 3) [rollback-playbook](./rollback-playbook.md) 준비 | 5분 지속 |
| Write 실패율 | Prometheus (`method=POST|PUT|PATCH|DELETE`) | `Invoke-RestMethod "http://localhost:9090/api/v1/query?query=$([uri]::EscapeDataString('sum(rate(http_server_requests_seconds_count{uri=~"/api/order-lot/.*",method=~"POST|PUT|PATCH|DELETE",status=~"5..|4.."}[5m]))/sum(rate(http_server_requests_seconds_count{uri=~"/api/order-lot/.*",method=~"POST|PUT|PATCH|DELETE"}[5m]))*100'))"` | `<= 0.5%` | 1) write retry=0 유지 확인 2) write 보호 정책 즉시 적용 3) [gateway-routing-matrix](./gateway-routing-matrix.md) 확인 | 5분 지속 |
| 데이터 정합성 | `migration/sql/r1-validation/06-order-lot-validation.sql` 결과 | `sqlcmd -S <server> -U <user> -P <pwd> -i migration/sql/r1-validation/06-order-lot-validation.sql -o migration/reports/R1-order-lot-output.txt` | `count=0`, `sum<=0.05%`, `sample=0/200`, `status<=0.5%p` | 1) 즉시 NO-GO 2) DB 복원 3) [rehearsal-R1-runbook](./rehearsal-R1-runbook.md) Rollback 실행 | 기준 1개라도 초과 즉시 |
| DB deadlock/timeout (order-lot 관련) | app 로그 + SQL XEvent | `rg -n "order-lot|deadlock|timeout|1205|1222" logs\ -S` | `deadlock=0`, `timeout=0/10분` | 1) 해당 트랜잭션 차단 2) write 경로 중지 3) [rollback-playbook](./rollback-playbook.md) 실행 | 1건 발생 즉시 |

## 5) 즉시 조치 우선순위
1. 안전 확보: `GATEWAY_EMERGENCY_STOP_ENABLED=true` 또는 도메인 write 차단.
2. 영향 축소: order-lot read-only fallback 유지, 고장 도메인 route rate-limit 하향.
3. 근본 조치: SQL/인덱스/정책 수정 후 smoke + migration-dry-run 재검증.
4. 복구 실패 시: `rollback-playbook` 수행 후 `NO-GO` 선언.

## 6) 최종 판정 체크
- [ ] 필수 게이트 5종 PASS (`build`, `unit-integration-test`, `contract-test`, `smoke-test`, `migration-dry-run`)
- [ ] 전역 지표 임계치 전부 충족
- [ ] order-lot 강화 지표 전부 충족
- [ ] 데이터 정합성 기준 충족 (`count=0`, `sum<=0.1%`, `sample=0/200`, `status<=1.0%p`)
- [ ] 롤백 시간 기준 충족 (`<=20분`)

**결정 규칙**
- 위 체크 중 1개라도 미충족이면 `NO-GO`.
- order-lot 강화 지표 1개라도 미충족이면 `NO-GO`.

## 7) 서명 섹션

| 역할 | 승인자 | 승인 시간 (KST) | 결정 (GO/NO-GO) | 근거 링크 |
|---|---|---|---|---|
| Dev Owner | `<name>` | `<yyyy-MM-dd HH:mm:ss>` | `<GO/NO-GO>` | `<runbooks/evidence/...>` |
| Codex (Validation) | `Codex` | `<yyyy-MM-dd HH:mm:ss>` | `<GO/NO-GO>` | `<migration/reports/validation-*.md>` |
| Ops Owner | `<name>` | `<yyyy-MM-dd HH:mm:ss>` | `<GO/NO-GO>` | `<dashboard/log/restore evidence>` |
| QA/Business Owner | `<name>` | `<yyyy-MM-dd HH:mm:ss>` | `<GO/NO-GO>` | `<UAT/rehearsal evidence>` |

## 8) 참고 런북
- [today-execution-R1](./today-execution-R1.md)
- [rehearsal-R1-runbook](./rehearsal-R1-runbook.md)
- [merge-gates-checklist](./merge-gates-checklist.md)
- [gateway-routing-matrix](./gateway-routing-matrix.md)
- [rollback-playbook](./rollback-playbook.md)
