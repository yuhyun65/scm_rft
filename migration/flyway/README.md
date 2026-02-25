# Flyway Baseline

Big-Bang 전환 초기 DB 스키마 버전을 관리합니다.

## 파일 규칙
- 파일명: `V<version>__<description>.sql`
- baseline: `V1__baseline.sql`
- core domains: `V2__core_domains.sql`
- auth/member lookup index baseline: `V3__auth_member_lookup_indexes.sql`
- auth credential schema: `V4__auth_credentials.sql`
- member search tuning indexes: `V5__member_search_tuning_indexes.sql`

## 적용 원칙
- SQL Server 기준으로 작성
- `IF OBJECT_ID ... IS NULL` 패턴으로 재실행 안전성 보장
- baseline 이후 변경은 새 버전 파일로만 추가

## 실행 예시
```powershell
flyway -locations=filesystem:migration/flyway -url=<jdbc-url> -user=<user> -password=<password> migrate
```
