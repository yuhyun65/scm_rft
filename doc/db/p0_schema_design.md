# P0 DB Schema Design (SCM_RFT)

- 작성일: 2026-02-25
- 범위: `dev_plan.md` 2.1 제품/기능의 P0 시나리오
- DB: SQL Server
- 적용 전략: Flyway (`V1` baseline + `V2` core domains)

## 1. 설계 원칙
- 서비스 계약(OpenAPI) 기준으로 테이블/컬럼을 최소 단위로 먼저 고정한다.
- Big-Bang 전환 리스크가 높은 도메인(`auth/member`, `order-lot`, `file`)과 P0 필수 도메인(`board`, `quality-doc`, `inventory`, `report`)을 우선 확정한다.
- 모든 테이블에 운영 추적을 위한 시간 컬럼(`created_at`, `updated_at` 또는 도메인 시각)을 포함한다.
- 상태값은 `CHECK` 제약으로 제한한다.

## 2. P0 도메인별 테이블

| Domain | Table | 용도 | Key |
|---|---|---|---|
| auth | `auth_sessions` | 액세스 세션 관리 | `session_id` |
| member | `members` | 회원/거래처 기본 정보 | `member_id` |
| order-lot | `orders`, `order_lots` | 주문/LOT 핵심 흐름 | `order_no`, `lot_no` |
| file | `upload_files` | 첨부 메타데이터 | `file_id` |
| board | `board_posts`, `board_post_attachments` | 게시글/첨부 연계 | `post_id`, `(post_id,file_id)` |
| quality-doc | `quality_documents`, `quality_document_acks` | 품질문서/수신확인 | `document_id`, `(document_id,member_id)` |
| inventory | `inventory_balances`, `inventory_movements` | 재고 잔량/이력 | `(item_code,warehouse_code)`, `movement_id` |
| report | `report_jobs` | 보고서 생성/상태 추적 | `job_id` |

## 3. 핵심 관계(FK)
- `board_posts.writer_member_id -> members.member_id`
- `board_post_attachments.post_id -> board_posts.post_id`
- `board_post_attachments.file_id -> upload_files.file_id`
- `quality_documents.publisher_member_id -> members.member_id`
- `quality_document_acks.document_id -> quality_documents.document_id`
- `quality_document_acks.member_id -> members.member_id`
- `report_jobs.requested_by_member_id -> members.member_id`
- `report_jobs.output_file_id -> upload_files.file_id`

## 4. 상태값 규칙
- `board_posts.status`: `ACTIVE`, `DELETED`, `HIDDEN`
- `quality_documents.status`: `ISSUED`, `RECEIVED`, `ARCHIVED`
- `inventory_movements.movement_type`: `IN`, `OUT`, `ADJUST`
- `report_jobs.status`: `QUEUED`, `RUNNING`, `COMPLETED`, `FAILED`

## 5. 인덱스 전략(P0)
- `board_posts(category_code, created_at)`
- `board_post_attachments(file_id)`
- `quality_documents(issued_at)`
- `quality_document_acks(member_id, ack_at)`
- `inventory_movements(item_code, warehouse_code, moved_at)`
- `report_jobs(status, requested_at)`
- `report_jobs(output_file_id)`

## 6. Flyway 적용 순서
1. `V1__baseline.sql`
2. `V2__core_domains.sql`

## 7. 후속 보완 항목
- 레거시 SP 파라미터와 컬럼 1:1 매핑 상세화(코드값/nullable/기본값).
- 성능 검증 후 복합 인덱스 튜닝.
- 감사 컬럼/이력 테이블(변경자, 변경사유) 확장.
