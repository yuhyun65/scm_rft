# file service

- 역할: 첨부파일 메타/저장소 관리
- 기본 포트: `8087`
- 기술 기준: Java 21, Spring Boot 3.x, Gradle 8.x
- API:
  - `POST /api/file/v1/files`
  - `GET /api/file/v1/files/{fileId}`
- 저장 테이블: `dbo.upload_files`
