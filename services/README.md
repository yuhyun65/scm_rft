# Services

MSA 서비스 코드를 관리합니다.

## 서비스 목록 및 기본 포트
- `auth` : 8081
- `member` : 8082
- `board` : 8083
- `quality-doc` : 8084
- `order-lot` : 8085
- `inventory` : 8086
- `file` : 8087
- `report` : 8088

## 빌드/실행
- 전체 빌드: `.\gradlew.bat build`
- 전체 테스트: `.\gradlew.bat test`
- 단일 서비스 실행 예시:
  - `.\gradlew.bat :services:auth:bootRun`
  - `.\gradlew.bat :services:member:bootRun`
