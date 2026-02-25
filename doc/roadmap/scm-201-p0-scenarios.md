# SCM-201 P0 Scenarios and API Contract Lock

- 작성일: 2026-02-25
- 목적: `dev_plan.md` 2.1 제품/기능 완료 기준의 P0 시나리오를 고정
- 범위: `auth/member/board/quality-doc/order-lot/inventory/file/report`

## 1. P0 사용자 시나리오

| ID | 시나리오 | 순서 | 완료 조건 |
|---|---|---|---|
| P0-F01 | 로그인 후 회원 조회 | `auth session` -> `member search/detail` | 토큰 발급 성공 + 회원조회 200 |
| P0-F02 | 주문/LOT 조회 | `order list lots` -> `lot detail` | 주문번호 기준 LOT 목록/상세 200 |
| P0-F03 | 첨부 메타 등록/조회 | `file register` -> `file get` | 파일 메타 생성 201 + 조회 200 |
| P0-F04 | 게시판 조회 | `board list` -> `board detail` | 게시글 목록/상세 200 |
| P0-F05 | 품질문서 수신 확인 | `quality-doc list` -> `ack` | 문서 목록 200 + ack 204 |
| P0-F06 | 재고 조회 | `inventory balance` -> `movement list` | 재고수량/이력 조회 200 |
| P0-F07 | 리포트 작업 | `report generate` -> `job status` | 생성 202 + 상태조회 200 |

## 2. API 입력/출력/오류코드 고정

| ID | Method/Path | 입력(필수) | 성공 응답 | 오류 응답 |
|---|---|---|---|---|
| P0-A01 | `POST /api/auth/v1/sessions` | `loginId`, `password` | `200 {accessToken, expiresAt}` | `400`, `401`, `423` |
| P0-A02 | `GET /api/member/v1/members` | `Authorization`, `keyword`(opt) | `200 {items[]}` | `401`, `403` |
| P0-A03 | `GET /api/member/v1/members/{memberId}` | `Authorization`, `memberId` | `200 {member}` | `401`, `403`, `404` |
| P0-A04 | `GET /api/order-lot/v1/orders/{orderNo}/lots` | `Authorization`, `orderNo` | `200 {items[]}` | `401`, `403`, `404` |
| P0-A05 | `GET /api/order-lot/v1/lots/{lotNo}` | `Authorization`, `lotNo` | `200 {lot}` | `401`, `403`, `404` |
| P0-A06 | `POST /api/file/v1/files` | `Authorization`, `domainKey`, `originalName`, `storagePath` | `201 {fileMetadata}` | `400`, `401`, `403` |
| P0-A07 | `GET /api/file/v1/files/{fileId}` | `Authorization`, `fileId` | `200 {fileMetadata}` | `401`, `403`, `404` |
| P0-A08 | `GET /api/board/v1/posts` | `Authorization` | `200 {items[]}` | `401`, `403` |
| P0-A09 | `GET /api/board/v1/posts/{postId}` | `Authorization`, `postId` | `200 {post}` | `401`, `403`, `404` |
| P0-A10 | `GET /api/quality-doc/v1/documents` | `Authorization` | `200 {items[]}` | `401`, `403` |
| P0-A11 | `POST /api/quality-doc/v1/documents/{documentId}/ack` | `Authorization`, `documentId` | `204` | `401`, `403`, `404`, `409` |
| P0-A12 | `GET /api/inventory/v1/items/{itemCode}/balance` | `Authorization`, `itemCode` | `200 {balance}` | `401`, `403`, `404` |
| P0-A13 | `GET /api/inventory/v1/movements` | `Authorization` | `200 {items[]}` | `401`, `403` |
| P0-A14 | `POST /api/report/v1/reports/{reportType}` | `Authorization`, `reportType`, payload | `202 {jobId,status}` | `400`, `401`, `403`, `422` |
| P0-A15 | `GET /api/report/v1/reports/jobs/{jobId}` | `Authorization`, `jobId` | `200 {job}` | `401`, `403`, `404` |

## 3. Gateway/보안 적용 기준
- 모든 P0 API는 Gateway를 통해서만 접근한다.
- `Authorization: Bearer <token>` 검증 실패 시 `401` 반환.
- 권한 부족 시 `403` 반환.
- 컷오버 긴급차단 시 전역 `503` 반환(`emergencyStop`).

## 4. 변경 통제 규칙
- 본 문서 변경 시 ADR 또는 PR 코멘트로 근거를 명시한다.
- P0 API 계약 변경은 `shared/contracts/*.openapi.yaml` 동시 갱신을 필수로 한다.
- P0 E2E 테스트 케이스는 본 문서 ID(`P0-F**`, `P0-A**`)를 테스트명에 매핑한다.
