# Legacy SP to TO-BE Mapping (Draft)

## 목적
- AS-IS Stored Procedure 중심 로직을 TO-BE API/DB 모델로 분해하기 위한 기준표.
- 이관 검증 시 건수/합계/샘플 비교의 기준 소스로 사용.

## 매핑 테이블

| Legacy SP | Domain | 주요 기능 | TO-BE API (초안) | TO-BE Table (초안) | 검증 포인트 |
|---|---|---|---|---|---|
| `sp_SCM_MemberShip` | auth/member | 로그인, 회원 조회 | `/api/auth/v1/sessions`, `/api/member/v1/members` | `members`, `auth_sessions` | 로그인 성공률, 회원 상태 일치 |
| `sp_SCM_OrderManager` | order-lot | 납품/LOT/거래명세 | `/api/order-lot/v1/orders/{orderNo}/lots` | `orders`, `order_lots` | 주문/LOT 건수, 수량 합계 |
| `sp_SCM_StokList` | inventory | 재고 조회 | `/api/inventory/v1/items/{itemCode}/balance` | `inventory_balances`(예정) | 품목별 재고 수량 |
| `sp_SCM_TrustBoard` | board | 게시글 조회/등록 | `/api/board/v1/posts` | `board_posts`(예정) | 게시글 건수/최근글 일치 |
| `sp_SCM_TrustNotice` | board/report | 공지/출력 | `/api/board/v1/posts`, `/api/report/v1/reports/{type}` | `board_posts`, `report_jobs` | 공지 목록/출력 결과 |
| `sp_SCM_TrustAODoc` | quality-doc | 품질문서 발행/수신 | `/api/quality-doc/v1/documents` | `quality_documents`(예정) | 문서 건수/상태 일치 |
| `sp_SCM_HelpPop` | board/member | 헬프성 조회 | `/api/member/v1/members` 등 | 도메인별 조회 테이블 | 조회 결과 샘플 일치 |

## 작성 규칙
- API는 OpenAPI 파일과 동일한 경로/스키마를 사용한다.
- 테이블명은 Flyway 버전 파일 기준으로 확정한다.
- 검증 포인트는 리허설 보고서 항목과 1:1로 연결한다.
