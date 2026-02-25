# 2.1 Product/Function Completion - Issue/PR Templates (10 Items)

아래는 `Issue 1개 = PR 1개` 실행 템플릿입니다.  
각 항목은 순서대로 진행하며, `Depends on`이 해소된 뒤 착수합니다.

## 1) SCM-201 P0 시나리오/아키텍처 고정

### Issue Title
`[SCM-201] Lock P0 scenarios and architecture decisions`

### Branch
`feature/scm-201-p0-architecture-lock`

### PR Title
`docs: lock p0 scenarios and architecture decisions`

### Depends on
- 없음

### Scope
- P0 핵심 사용자 시나리오 확정
- Gateway 구현체 고정(예: Spring Cloud Gateway)
- DB 전략 고정(공유 DB + 도메인 테이블 분리)
- ADR-003/ADR-004 작성

### Checklist
- [ ] P0 시나리오 입력/출력/오류코드 표 작성
- [ ] ADR-003 작성(게이트웨이 선택 근거)
- [ ] ADR-004 작성(DB 전략 근거)
- [ ] `dev_plan.md`/`roadmap` 반영

### DoD
- 기술 선택 변경 시 ADR 갱신 규칙 확정
- 팀 내 기준 문서 1개로 참조 가능

---

## 2) SCM-202 Gateway 실행체 추가

### Issue Title
`[SCM-202] Add gateway runtime service with route controls`

### Branch
`feature/scm-202-gateway-runtime`

### PR Title
`feat(gateway): add runtime gateway service and route controls`

### Depends on
- `SCM-201`

### Scope
- `services/gateway` 모듈 생성
- 라우팅/timeout/retry/rate-limit/emergency stop 적용
- `docker-compose.yml`에 gateway 연결

### Checklist
- [ ] gateway 모듈/설정 추가
- [ ] 정책 파일 로딩 연결
- [ ] `/api/*` 라우팅 검증
- [ ] emergency stop 503 검증

### DoD
- gateway 경유 트래픽만 허용
- 긴급차단 동작 증적(요청/응답 로그) 확보

---

## 3) SCM-203 Auth 세션 API 구현

### Issue Title
`[SCM-203] Implement auth session API`

### Branch
`feature/scm-203-auth-session-api`

### PR Title
`feat(auth): implement session login api`

### Depends on
- `SCM-201`, `SCM-202`

### Scope
- `POST /api/auth/v1/sessions`
- 로그인 실패/성공 응답코드 분기
- 토큰 만료 정책 기본 구현

### Checklist
- [ ] controller/service/repository 구현
- [ ] 요청/응답 DTO 구현
- [ ] 실패 케이스(401) 테스트
- [ ] 계약(OpenAPI) 일치 검증

### DoD
- 계약 테스트 통과
- 인증 성공/실패 흐름 재현 가능

---

## 4) SCM-204 Member 조회 API 구현

### Issue Title
`[SCM-204] Implement member query APIs`

### Branch
`feature/scm-204-member-query-api`

### PR Title
`feat(member): implement member query apis`

### Depends on
- `SCM-203`

### Scope
- `GET /api/member/v1/members`
- `GET /api/member/v1/members/{memberId}`

### Checklist
- [ ] 검색/상세 조회 구현
- [ ] 인증 연동(토큰 필요) 적용
- [ ] 404/200 케이스 테스트
- [ ] 응답 스키마 계약 일치

### DoD
- 인증 포함 멤버 조회 시나리오 통과
- OpenAPI 대비 필드 불일치 0건

---

## 5) SCM-205 DB 연동 표준화

### Issue Title
`[SCM-205] Standardize datasource, flyway, and persistence baseline`

### Branch
`feature/scm-205-db-integration-baseline`

### PR Title
`feat(core): add datasource flyway and persistence baseline`

### Depends on
- `SCM-201`

### Scope
- datasource 프로파일 정리
- Flyway 실행 연결
- repository 계층 표준 패턴 도입

### Checklist
- [ ] SQL Server 연결 설정 추가
- [ ] Flyway 실행 확인
- [ ] 공통 예외/트랜잭션 정책 정의
- [ ] 샘플 CRUD 테스트 추가

### DoD
- 서비스 기동 시 마이그레이션 자동 적용
- DB read/write 최소 검증 통과

---

## 6) SCM-206 Order-Lot 핵심 API 구현

### Issue Title
`[SCM-206] Implement order-lot P0 APIs`

### Branch
`feature/scm-206-order-lot-p0`

### PR Title
`feat(order-lot): implement p0 order lot apis`

### Depends on
- `SCM-203`, `SCM-205`

### Scope
- 주문별 LOT 조회
- LOT 상세 조회
- 필요한 저장소/쿼리 구현

### Checklist
- [ ] order-lot service API 구현
- [ ] DB 매핑 구현
- [ ] 에러코드 처리
- [ ] 통합 테스트 추가

### DoD
- P0 주문/LOT 조회 시나리오 통과
- 성능 병목 쿼리 1차 확인 완료

---

## 7) SCM-207 File API 구현

### Issue Title
`[SCM-207] Implement file metadata and attachment flow`

### Branch
`feature/scm-207-file-api`

### PR Title
`feat(file): implement file metadata and attachment flow`

### Depends on
- `SCM-205`

### Scope
- 파일 메타 등록/조회
- 도메인 첨부 참조 연결

### Checklist
- [ ] `/api/file/v1/files` POST/GET 구현
- [ ] `upload_files` 저장/조회 구현
- [ ] 파일 경로 검증 로직 추가
- [ ] API 테스트 추가

### DoD
- 파일 메타 등록/조회 시나리오 통과
- 첨부 참조 무결성 검증 통과

---

## 8) SCM-208 Board + Quality-Doc MVP

### Issue Title
`[SCM-208] Implement board and quality-doc P0 APIs`

### Branch
`feature/scm-208-board-quality-mvp`

### PR Title
`feat(board-quality): implement board and quality-doc p0 apis`

### Depends on
- `SCM-204`, `SCM-205`, `SCM-207`

### Scope
- 게시글 목록/상세
- 품질문서 목록/ack

### Checklist
- [ ] board API 구현
- [ ] quality-doc API 구현
- [ ] 첨부 연동(게시글/문서)
- [ ] 테스트 추가

### DoD
- board/quality-doc P0 시나리오 통과
- 인증/권한 적용 확인

---

## 9) SCM-209 Inventory + Report MVP

### Issue Title
`[SCM-209] Implement inventory and report P0 APIs`

### Branch
`feature/scm-209-inventory-report-mvp`

### PR Title
`feat(inventory-report): implement inventory and report p0 apis`

### Depends on
- `SCM-205`, `SCM-204`

### Scope
- 재고 balance/movement 조회
- report job 생성/상태 조회

### Checklist
- [ ] inventory API 구현
- [ ] report API 구현
- [ ] report_jobs 상태전이 처리
- [ ] 테스트 추가

### DoD
- 8개 서비스 P0 endpoint 응답 가능
- report job 상태조회 정상 동작

---

## 10) SCM-210 P0 E2E/CI 실효성 강화 및 2.1 완료판정

### Issue Title
`[SCM-210] Add P0 e2e and harden CI gates for 2.1 completion`

### Branch
`feature/scm-210-p0-e2e-ci-hardening`

### PR Title
`test(ci): add p0 e2e and harden ci gates`

### Depends on
- `SCM-202` ~ `SCM-209`

### Scope
- gateway 기준 E2E 자동화
- smoke/contract/migration 게이트를 실행 검증 중심으로 강화
- 2.1 완료 체크리스트 문서화

### Checklist
- [ ] P0 E2E 테스트 케이스 추가
- [ ] CI smoke에 실제 API 호출 추가
- [ ] migration 검증 실데이터 기반 전환
- [ ] 2.1 완료 증적 문서 작성

### DoD
- `dev_plan.md 2.1` 3개 조건 모두 증적 포함 충족
- CI 파이프라인 green + 재현 가능한 테스트 보고서 확보
