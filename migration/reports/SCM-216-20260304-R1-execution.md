# SCM-213 R1 Execution Result

- RunId: SCM-216-20260304-R1
- GeneratedAt: 2026-03-04 14:26:34
- SqlDir: C:\Users\CMN-091\projects\SCM_RFT_wt_216\migration\sql\r1-validation
- SqlExecution: EXECUTED

## Domain Execution Order
auth -> member -> file -> inventory -> report -> order-lot -> board -> quality-doc

## Raw Outputs
| Domain | Output File |
|---|---|
| auth | migration\reports\R1-SCM-216-20260304-R1-auth.out.txt |
| member | migration\reports\R1-SCM-216-20260304-R1-member.out.txt |
| file | migration\reports\R1-SCM-216-20260304-R1-file.out.txt |
| inventory | migration\reports\R1-SCM-216-20260304-R1-inventory.out.txt |
| report | migration\reports\R1-SCM-216-20260304-R1-report.out.txt |
| order-lot | migration\reports\R1-SCM-216-20260304-R1-order-lot.out.txt |
| board | migration\reports\R1-SCM-216-20260304-R1-board.out.txt |
| quality-doc | migration\reports\R1-SCM-216-20260304-R1-quality-doc.out.txt |

## R1 Thresholds
- count mismatch = 0
- sum delta <= 0.1%
- sample mismatch = 0/200
- status delta <= 1.0%p

## Template Appendix

# SCM-213 R1 Validation Report Template

## 1) Run Metadata
- RunId: `SCM-216-20260304-R1`
- RunId 규칙:
  - Prefix: `R1-`
  - Timestamp: `yyyyMMdd-HHmmss` (KST 기준)
  - Suffix: `DEV|STG|PRD-REHEARSAL`
  - 예시: `R1-20260226-153000-STG`
- 실행환경:
  - Legacy DB: `<MES_HI_LEGACY>`
  - Target DB: `<MES_HI>`
  - Host/Container: `<hostname or container>`
  - Tool: `sqlcmd` / `SSMS`
- 실행자:
  - Dev: `<name>`
  - Codex: `<name>`
- 실행시간:
  - StartedAt: `2026-03-04 14:26:34`
  - EndedAt: `2026-03-04 14:26:34`
  - Duration(min): `<number>`

## 2) SQL 실행 파일 경로
- `migration/sql/r1-validation/01-auth-validation.sql`
- `migration/sql/r1-validation/02-member-validation.sql`
- `migration/sql/r1-validation/03-file-validation.sql`
- `migration/sql/r1-validation/04-inventory-validation.sql`
- `migration/sql/r1-validation/05-report-validation.sql`
- `migration/sql/r1-validation/06-order-lot-validation.sql`
- `migration/sql/r1-validation/07-board-validation.sql`
- `migration/sql/r1-validation/08-quality-doc-validation.sql`

## 3) 결과 요약
| 항목 | 값 | 판정 |
|---|---:|---|
| 실행 도메인 수 | `<8>` | `<PASS/FAIL>` |
| count mismatch 도메인 수 | `<n>` | `<PASS/FAIL>` |
| sum 임계치 초과 도메인 수 | `<n>` | `<PASS/FAIL>` |
| sample mismatch 초과 도메인 수 | `<n>` | `<PASS/FAIL>` |
| status delta 초과 도메인 수 | `<n>` | `<PASS/FAIL>` |
| 최종 판정 | `<GO/NO-GO>` | `<확정>` |

## 4) 도메인별 결과

### 4.1 auth
| 검증 항목 | legacy | target | 비교값 | 임계치 | 판정 | 증적 경로 |
|---|---:|---:|---:|---:|---|---|
| count |  |  | `mismatch=` | `0` |  | `migration/reports/<file>` |
| sum(failed_count) |  |  | `delta%=` | `<=0.1%` |  | `migration/reports/<file>` |
| sample(200) |  |  | `mismatch=/200` | `0/200` |  | `migration/reports/<file>` |
| status(password_algo) |  |  | `max_delta_pp=` | `<=1.0%p` |  | `migration/reports/<file>` |

### 4.2 member
| 검증 항목 | legacy | target | 비교값 | 임계치 | 판정 | 증적 경로 |
|---|---:|---:|---:|---:|---|---|
| count |  |  | `mismatch=` | `0` |  | `migration/reports/<file>` |
| sum(active_count) |  |  | `delta%=` | `<=0.1%` |  | `migration/reports/<file>` |
| sample(200) |  |  | `mismatch=/200` | `0/200` |  | `migration/reports/<file>` |
| status(status) |  |  | `max_delta_pp=` | `<=1.0%p` |  | `migration/reports/<file>` |

### 4.3 file
| 검증 항목 | legacy | target | 비교값 | 임계치 | 판정 | 증적 경로 |
|---|---:|---:|---:|---:|---|---|
| count |  |  | `mismatch=` | `0` |  | `migration/reports/<file>` |
| sum(DATALENGTH(storage_path)) |  |  | `delta%=` | `<=0.1%` |  | `migration/reports/<file>` |
| sample(200) |  |  | `mismatch=/200` | `0/200` |  | `migration/reports/<file>` |
| status(domain_key) |  |  | `max_delta_pp=` | `<=1.0%p` |  | `migration/reports/<file>` |

### 4.4 inventory
| 검증 항목 | legacy | target | 비교값 | 임계치 | 판정 | 증적 경로 |
|---|---:|---:|---:|---:|---|---|
| count(balances/movements) |  |  | `mismatch=` | `0` |  | `migration/reports/<file>` |
| sum(quantity) |  |  | `delta%=` | `<=0.1%` |  | `migration/reports/<file>` |
| sample(200, movements) |  |  | `mismatch=/200` | `0/200` |  | `migration/reports/<file>` |
| status(movement_type) |  |  | `max_delta_pp=` | `<=1.0%p` |  | `migration/reports/<file>` |

### 4.5 report
| 검증 항목 | legacy | target | 비교값 | 임계치 | 판정 | 증적 경로 |
|---|---:|---:|---:|---:|---|---|
| count |  |  | `mismatch=` | `0` |  | `migration/reports/<file>` |
| sum(failed_count) |  |  | `delta%=` | `<=0.1%` |  | `migration/reports/<file>` |
| sample(200) |  |  | `mismatch=/200` | `0/200` |  | `migration/reports/<file>` |
| status(status) |  |  | `max_delta_pp=` | `<=1.0%p` |  | `migration/reports/<file>` |

### 4.6 order-lot
| 검증 항목 | legacy | target | 비교값 | 임계치 | 판정 | 증적 경로 |
|---|---:|---:|---:|---:|---|---|
| count(orders/lots) |  |  | `mismatch=` | `0` |  | `migration/reports/<file>` |
| sum(order_lots.quantity) |  |  | `delta%=` | `<=0.1%` |  | `migration/reports/<file>` |
| sample(200, lots) |  |  | `mismatch=/200` | `0/200` |  | `migration/reports/<file>` |
| status(orders.status) |  |  | `max_delta_pp=` | `<=1.0%p` |  | `migration/reports/<file>` |

### 4.7 board
| 검증 항목 | legacy | target | 비교값 | 임계치 | 판정 | 증적 경로 |
|---|---:|---:|---:|---:|---|---|
| count |  |  | `mismatch=` | `0` |  | `migration/reports/<file>` |
| sum(notice_count) |  |  | `delta%=` | `<=0.1%` |  | `migration/reports/<file>` |
| sample(200) |  |  | `mismatch=/200` | `0/200` |  | `migration/reports/<file>` |
| status(status) |  |  | `max_delta_pp=` | `<=1.0%p` |  | `migration/reports/<file>` |

### 4.8 quality-doc
| 검증 항목 | legacy | target | 비교값 | 임계치 | 판정 | 증적 경로 |
|---|---:|---:|---:|---:|---|---|
| count(documents/acks) |  |  | `mismatch=` | `0` |  | `migration/reports/<file>` |
| sum(ack_count) |  |  | `delta%=` | `<=0.1%` |  | `migration/reports/<file>` |
| sample(200, documents) |  |  | `mismatch=/200` | `0/200` |  | `migration/reports/<file>` |
| status(documents.status) |  |  | `max_delta_pp=` | `<=1.0%p` |  | `migration/reports/<file>` |

## 5) 이슈 / 조치
| Domain | 이슈 유형(count/sum/sample/status) | 증상 | 원인 | 조치 내용 | 재검증 결과 |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

## 6) Go/No-Go 초안
| 기준 | 결과 | 판정 |
|---|---|---|
| count mismatch = 0 |  |  |
| sum delta <= 0.1% |  |  |
| sample mismatch = 0/200 |  |  |
| status delta <= 1.0%p |  |  |
| 종합 |  | `<GO / NO-GO>` |

## 7) R1 판정 체크 규칙 (고정)
- `count mismatch = 0` 이 아니면 `NO-GO`.
- `sum delta > 0.1%` 인 도메인이 1개라도 있으면 `NO-GO`.
- `sample mismatch > 0/200` 인 도메인이 1개라도 있으면 `NO-GO`.
- `status delta > 1.0%p` 인 도메인이 1개라도 있으면 `NO-GO`.

## 8) 부록 (실행 로그 / 커맨드)
```powershell
# 예시: sqlcmd 실행
# sqlcmd -S <server> -U <user> -P <password> -i migration/sql/r1-validation/01-auth-validation.sql -o migration/reports/R1-auth-output.txt
```


