# HISCM 신규 UI 프로젝트 반영 계획

> **기준 설계:** `doc/ui-design-proposal.html` (9개 화면 인터랙티브 프로토타입)
> **기준 코드베이스:** `frontend/apps/web-portal` (React 18 + TypeScript + Vite)
> **연계 문서:** `doc/dev_plan.md`, `runbooks/agentic-orchestration.md`

---

## 1. 현재 프론트엔드 상태 진단

### 1.1 현재 구조 (As-Is)

```
frontend/
├── apps/
│   └── web-portal/          ← React 18 + Vite (port 5173)
│       └── src/
│           ├── App.tsx       ← 단일 페이지, 패널 수직 배치
│           ├── styles.css    ← 단순 배경 그라데이션
│           └── features/     ← API 검증용 raw form 패널들
│               ├── auth-member-panel.tsx
│               ├── order-lot-panel.tsx
│               ├── board-qualitydoc-panel.tsx
│               ├── inventory-file-report-panel.tsx
│               └── cutover-runner-panel.tsx
└── packages/
    ├── api-client/           ← OpenAPI 자동 생성 타입 + 클라이언트
    └── ui/                   ← 공유 유틸리티 (현재 최소 구현)
```

**현재 한계:**
- 라우팅 없음 — 모든 패널이 단일 스크롤 페이지에 수직 나열
- 인증 상태 관리 없음 — localStorage 직접 접근 분산
- UI 컴포넌트 라이브러리 없음 — 개발용 raw form 수준
- 사이드바/헤더 레이아웃 없음

### 1.2 목표 구조 (To-Be)

```
frontend/
├── apps/
│   └── web-portal/
│       └── src/
│           ├── App.tsx              ← Router Provider + AuthGuard 진입점
│           ├── layouts/
│           │   ├── AppLayout.tsx    ← 사이드바 + 헤더 공통 레이아웃
│           │   └── AuthLayout.tsx   ← 로그인 전용 레이아웃
│           ├── pages/               ← 화면별 페이지 컴포넌트
│           │   ├── LoginPage.tsx
│           │   ├── DashboardPage.tsx
│           │   ├── OrderListPage.tsx
│           │   ├── OrderDetailPage.tsx
│           │   ├── InventoryPage.tsx
│           │   ├── MemberPage.tsx
│           │   ├── QualityDocPage.tsx
│           │   ├── BoardPage.tsx
│           │   └── ReportPage.tsx
│           ├── components/          ← 재사용 공통 컴포넌트
│           │   ├── Sidebar.tsx
│           │   ├── Header.tsx
│           │   ├── Table/
│           │   ├── StatusBadge.tsx
│           │   ├── KpiCard.tsx
│           │   └── StockBar.tsx
│           ├── store/               ← 전역 상태 (인증 토큰 등)
│           │   └── authStore.ts
│           └── features/            ← 도메인별 훅/로직 (기존 패널 분리)
└── packages/
    ├── api-client/                  ← (기존 유지, 타입 활용)
    └── ui/                          ← 디자인 토큰 + 공통 컴포넌트 이관
```

---

## 2. 추가 패키지 목록

### 2.1 필수 패키지 (web-portal)

| 패키지 | 용도 | 설치 명령 |
|---|---|---|
| `react-router-dom@6` | 화면 라우팅 | `pnpm add react-router-dom` |
| `zustand` | 인증 토큰 전역 상태 | `pnpm add zustand` |
| `@tanstack/react-query` | API 요청 캐싱/로딩 상태 | `pnpm add @tanstack/react-query` |
| `clsx` | 조건부 className 병합 | `pnpm add clsx` |

### 2.2 선택 패키지 (운영 단계 고려)

| 패키지 | 용도 | 비고 |
|---|---|---|
| `recharts` | 대시보드 차트 | KPI 바 차트 / 추이 그래프 |
| `react-hook-form` | 폼 유효성 검사 | 주문 등록, 거래처 등록 폼 |
| `@headlessui/react` | 접근성 드롭다운/모달 | 상태 변경 다이얼로그 |
| `date-fns` | 날짜 포맷 | 납기일, 등록일 표시 |

### 2.3 CSS 전략

기존 `styles.css` 를 유지하면서 **CSS 변수(Design Token) 기반**으로 확장:

```css
/* packages/ui/src/tokens.css */
:root {
  --color-primary:      #1e40af;
  --color-primary-dark: #1e3a8a;
  --color-success:      #16a34a;
  --color-warning:      #d97706;
  --color-danger:       #dc2626;
  --sidebar-width:      220px;
  --header-height:      56px;
  --radius-card:        8px;
}
```

`packages/ui` 에서 토큰을 관리하고 `web-portal` 에서 임포트하면 일관성 유지.

> **Tailwind CSS 대안:** 프로젝트 규모를 고려하면 CSS 변수 방식이 빌드 설정 부담이 적고 MSA 전환 과도기에 적합. 운영 안정화 후 Tailwind 도입 재검토 가능.

---

## 3. 라우팅 구조

```
/                  → /dashboard (리다이렉트)
/login             → LoginPage (AuthLayout)
/dashboard         → DashboardPage (AppLayout)
/orders            → OrderListPage
/orders/:orderId   → OrderDetailPage
/inventory         → InventoryPage
/members           → MemberPage
/quality-docs      → QualityDocPage
/board             → BoardPage
/reports           → ReportPage
```

**인증 가드 흐름:**

```
App.tsx
└── <RouterProvider>
    ├── <Route path="/login" element={<AuthLayout><LoginPage /></AuthLayout>} />
    └── <Route element={<AuthGuard />}>          ← 토큰 없으면 /login 리다이렉트
        └── <Route element={<AppLayout />}>      ← 사이드바 + 헤더
            ├── /dashboard
            ├── /orders  + /orders/:id
            ├── /inventory
            └── ...
```

---

## 4. 페이지별 구현 매핑

### 4.1 LoginPage — `auth` 서비스 연동

| 항목 | 내용 |
|---|---|
| API | `POST /api/auth/v1/login` |
| 상태 | `authStore.ts` — `accessToken`, `memberId`, `roles` 저장 |
| 성공 시 | `navigate('/dashboard')` |
| 기존 코드 재활용 | `features/auth-member-panel.tsx` → 로그인 로직 추출 |

```tsx
// store/authStore.ts (Zustand)
interface AuthState {
  accessToken: string;
  memberId: string;
  roles: string[];
  setAuth: (token: string, memberId: string, roles: string[]) => void;
  clearAuth: () => void;
}
```

---

### 4.2 DashboardPage — 복합 데이터 집계

| 항목 | 내용 |
|---|---|
| API | `GET /api/order-lot/v1/orders?status=IN_PROGRESS` (진행 중 주문 수) |
| API | `GET /api/inventory/v1/balances` (재고 경고 품목 필터) |
| API | `GET /api/quality-doc/v1/documents?status=ACTIVE` (승인 대기 수) |
| 구현 전략 | `useQuery` parallel fetch → KPI 카드 4종 렌더링 |
| 차트 | 주간 집계는 `report` 서비스 또는 프론트 로컬 집계 |

---

### 4.3 OrderListPage / OrderDetailPage — `order-lot` 서비스

| 항목 | 내용 |
|---|---|
| 목록 API | `GET /api/order-lot/v1/orders` (supplierId, status, keyword, page, size) |
| 상세 API | `GET /api/order-lot/v1/orders/{orderId}` |
| LOT 연결 | `GET /api/order-lot/v1/lots?orderId={id}` |
| 상태 변경 | `PATCH /api/order-lot/v1/orders/{id}/status` |
| 기존 코드 | `features/order-lot-panel.tsx` → `useOrderList`, `useOrderDetail` 훅으로 분리 |

---

### 4.4 InventoryPage — `inventory` 서비스

| 항목 | 내용 |
|---|---|
| 재고 조회 | `GET /api/inventory/v1/balances` (itemCode, warehouseCode, page, size) |
| 이동 이력 | `GET /api/inventory/v1/movements` |
| 특이 사항 | 재고율 계산 = `currentStock / safetyStock * 100` — 프론트 계산 |
| 재고 경고 | 재고율 < 70% 시 warning 색상, < 30% 시 danger 색상 적용 |

---

### 4.5 MemberPage — `member` 서비스

| 항목 | 내용 |
|---|---|
| 목록 | `GET /api/member/v1/members` (keyword, status, page, size) |
| 상세 | `GET /api/member/v1/members/{memberId}` |
| 기존 코드 | `features/auth-member-panel.tsx` → Member 관련 로직 분리 |

---

### 4.6 QualityDocPage — `quality-doc` 서비스

| 항목 | 내용 |
|---|---|
| 목록 | `GET /api/quality-doc/v1/documents` (status, keyword, page, size) |
| ACK 승인 | `POST /api/quality-doc/v1/documents/{id}/ack` |
| 특이 사항 | ACK는 **idempotent** — 동일 요청 2회 전송 안전 |
| 기존 코드 | `features/board-qualitydoc-panel.tsx` → QualityDoc 로직 분리 |

---

### 4.7 BoardPage — `board` 서비스

| 항목 | 내용 |
|---|---|
| 목록 | `GET /api/board/v1/posts` (boardType, keyword, page, size) |
| 작성 | `POST /api/board/v1/posts` |
| 상세 | `GET /api/board/v1/posts/{postId}` |
| 첨부 | `fileId` 참조 → `file` 서비스 URL로 다운로드 연결 |

---

### 4.8 ReportPage — `report` 서비스

| 항목 | 내용 |
|---|---|
| 생성 요청 | `POST /api/report/v1/jobs` (reportType, period, format) |
| 상태 조회 | `GET /api/report/v1/jobs/{jobId}` |
| 폴링 | `useQuery + refetchInterval` 로 COMPLETED 상태까지 주기적 확인 |
| 다운로드 | `GET /api/report/v1/jobs/{jobId}/download` → `file` 서비스 연결 |

---

## 5. 구현 순서 (GitHub Issue 단위)

기존 `dev_plan.md` Phase 구조와 연동하여 프론트엔드 이슈를 추가합니다.

### Phase 2-FE: 인증 + 라우팅 기반 (우선 착수)

| 이슈 ID | 제목 | 예상 규모 |
|---|---|---|
| SCM-FE-001 | 라우팅 구조 + AppLayout + AuthLayout 구현 | S (반나절) |
| SCM-FE-002 | LoginPage + authStore (Zustand) + AuthGuard | S (반나절) |
| SCM-FE-003 | 공통 컴포넌트: Sidebar, Header, StatusBadge, KpiCard | M (1일) |

**브랜치 예시:** `feature/scm-fe-001-routing-layout`

---

### Phase 3-FE: 핵심 도메인 화면

| 이슈 ID | 제목 | 예상 규모 |
|---|---|---|
| SCM-FE-004 | DashboardPage (KPI 4종 + 최근 활동) | M (1일) |
| SCM-FE-005 | OrderListPage + OrderDetailPage | L (1.5일) |
| SCM-FE-006 | InventoryPage (재고율 바 포함) | M (1일) |

---

### Phase 4-FE: 나머지 도메인 화면

| 이슈 ID | 제목 | 예상 규모 |
|---|---|---|
| SCM-FE-007 | MemberPage | S (반나절) |
| SCM-FE-008 | QualityDocPage + ACK 승인 흐름 | M (1일) |
| SCM-FE-009 | BoardPage (목록 + 상세 + 작성) | M (1일) |
| SCM-FE-010 | ReportPage (비동기 job 폴링) | M (1일) |

---

### Phase 5-FE: 운영 품질 강화

| 이슈 ID | 제목 | 예상 규모 |
|---|---|---|
| SCM-FE-011 | 에러 핸들링 (401 자동 로그아웃, 404/500 페이지) | S |
| SCM-FE-012 | 로딩 스켈레톤 + 페이지네이션 공통 컴포넌트 | S |
| SCM-FE-013 | E2E 스모크 시나리오 (e2e-smoke.mjs 확장) | M |

---

## 6. 기존 features/ 코드 재활용 전략

현재 `features/` 폴더에 있는 패널 코드는 **API 연동 로직**이 이미 구현되어 있습니다. 버리지 않고 다음과 같이 분리 재활용합니다.

| 기존 파일 | 추출할 훅 | 사용 페이지 |
|---|---|---|
| `auth-member-panel.tsx` | `useLogin()`, `useMemberSearch()` | LoginPage, MemberPage |
| `order-lot-panel.tsx` | `useOrderList()`, `useOrderDetail()`, `useOrderStatusChange()` | OrderListPage, OrderDetailPage |
| `board-qualitydoc-panel.tsx` | `useBoardPosts()`, `useQualityDocs()`, `useDocAck()` | BoardPage, QualityDocPage |
| `inventory-file-report-panel.tsx` | `useInventoryBalances()`, `useReportJob()` | InventoryPage, ReportPage |

**리팩토링 원칙:**
1. API 호출 로직 → `features/{domain}/hooks.ts` 로 이동
2. UI 렌더링 → `pages/{Domain}Page.tsx` 에서 훅 사용
3. 기존 패널 파일은 리팩토링 완료 후 삭제

---

## 7. 7-Gate 체크리스트 (프론트엔드 적용)

| 게이트 | 프론트엔드 대응 |
|---|---|
| `build` | `pnpm -r build` → TypeScript 컴파일 오류 0건 |
| `unit-integration-test` | Vitest 테스트 (기존 `.test.ts` 파일 확장) |
| `contract-test` | `api-client` 생성 타입 기반 타입 검증 |
| `lint-static-analysis` | `tsc --noEmit` + ESLint 추가 (SCM-FE-011 시 도입) |
| `smoke-test` | `scripts/e2e-smoke.mjs` 에 로그인→주문목록 시나리오 추가 |
| `security-scan` | `pnpm audit` → 고위험 취약점 0건 |
| `migration-dry-run` | 프론트엔드 해당 없음 (백엔드 게이트만 적용) |

---

## 8. 즉시 실행 순서 (다음 Agentic Run)

**오늘 바로 착수 가능한 첫 번째 액션:**

```bash
# 1. 필수 패키지 설치
cd frontend/apps/web-portal
pnpm add react-router-dom zustand @tanstack/react-query clsx

# 2. SCM-FE-001 브랜치 생성
git checkout feature/to-be-dev-env-bootstrap
git checkout -b feature/scm-fe-001-routing-layout

# 3. AppLayout 뼈대 작성
#    → src/layouts/AppLayout.tsx (사이드바 + 헤더)
#    → src/layouts/AuthLayout.tsx (로그인 전용)
#    → src/App.tsx 라우터 구조 교체

# 4. build gate 통과 확인
cd ../..
pnpm build
```

**Codex 프롬프트 예시 (템플릿 B 사용):**

```
[SCM-FE-001] React Router + AppLayout 구현

기준 브랜치: feature/to-be-dev-env-bootstrap
이슈 브랜치: feature/scm-fe-001-routing-layout

구현 내용:
1. pnpm add react-router-dom zustand @tanstack/react-query clsx
2. src/layouts/AppLayout.tsx — 사이드바(220px) + 헤더(56px) + 메인 레이아웃
   - 사이드바 메뉴: 대시보드/주문관리/재고현황/거래처관리/품질문서/게시판/보고서
   - 헤더: 로고 + 현재 경로 + 사용자명 표시
3. src/layouts/AuthLayout.tsx — 로그인 전용 중앙 정렬 레이아웃
4. src/App.tsx — RouterProvider + Route 구조 교체
   (기존 패널들은 임시로 유지, 라우팅 구조만 먼저 적용)
5. src/styles.css — CSS 변수(--color-primary 등 6종) 추가
6. pnpm build 통과 확인

DoD:
- TypeScript 컴파일 오류 0건
- /login 경로 접근 시 AuthLayout 렌더링
- /dashboard 경로 접근 시 AppLayout + 사이드바 렌더링
- build gate PASS
```

---

*최초 작성: 2026-03-17 | 연계: doc/ui-design-proposal.html, doc/dev_plan.md*
