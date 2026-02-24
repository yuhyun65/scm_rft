# Flyway Baseline

Big-Bang 전환 초기 기준 스키마를 관리합니다.

## 파일 규칙
- 파일명: `V<version>__<description>.sql`
- 현재 baseline: `V1__baseline.sql`

## 적용 원칙
- SQL Server 기준으로 작성
- `IF OBJECT_ID ... IS NULL` 패턴으로 재실행 안정성 확보
- baseline 이후 변경은 무조건 새 버전 파일로 추가

## 실행 예시
```powershell
flyway -locations=filesystem:migration/flyway -url=<jdbc-url> -user=<user> -password=<password> migrate
```
