# Migration

데이터 이관 스크립트와 검증 스크립트를 관리합니다.

## 원칙
- 재실행 가능한 스크립트로 작성
- Dry-run과 실제 실행을 분리
- 이관 결과 검증(건수/합계/샘플) 자동화

## 권장 구조
```text
migration/
  flyway/
  scripts/
  verify/
  reports/
  backups/
```

## Dry-Run and Validation
- Dry-run:
  - `powershell -ExecutionPolicy Bypass -File .\migration\scripts\dry-run.ps1`
- Validation:
  - `powershell -ExecutionPolicy Bypass -File .\migration\verify\validate-migration.ps1`
- Sample config:
  - `migration/verify/config.sample.json`

## Baseline
- Flyway baseline:
  - `migration/flyway/V1__baseline.sql`
