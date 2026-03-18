# Browser Click Test Checklist

## Preconditions
- Backend started with `docker compose` actual-topology stack
- Demo data seeded with `scripts/seed-demo-data.ps1`
- Auth/member validation completed with `smoke-gateway-auth-member-e2e.ps1 -SeedData:$false`
- Frontend dev server started with `scripts/frontend-dev.ps1`
- Browser open at `http://localhost:5173`

## Login Credentials
- User demo: `smoke-user / password`
- Buyer demo: `demo-buyer-001 / password`
- Quality demo: `demo-quality-001 / password`
- Admin demo: `smoke-admin / password`

## 1. Login + Member Route
- [ ] Login page visible at `/login`
- [ ] Enter `smoke-user / password`
- [ ] Click `로그인`
- [ ] Redirect to `/dashboard`
- [ ] Open left menu `거래처 관리`
- [ ] In search, keyword=`demo`, status=`ACTIVE`
- [ ] Click `조회`
- [ ] Table shows multiple `demo-*` members
- [ ] Open `거래처 등록` or create form section
- [ ] Enter a new `memberId`, `memberName`, `status`
- [ ] Click `등록`
- [ ] Success banner appears
- [ ] Click one `상세`
- [ ] Route changes to `/members/:memberId`
- [ ] Detail page shows `memberId`, `memberName`, `status`

## 2. Order Route
- [ ] Open left menu `주문 관리`
- [ ] In search, keyword=`DEMO-ORDER`
- [ ] Click `조회`
- [ ] Order list returns multiple records
- [ ] Click one order `상세`
- [ ] Route changes to `/orders/:orderId`
- [ ] Order detail shows order status, expected delivery, total lot count
- [ ] Open order create form and create one new order
- [ ] Open order update form and submit changed supplier/date
- [ ] Enter `DEMO-LOT-1002-A` and click `LOT 조회`
- [ ] Open lot add form and add one lot
- [ ] For full feature demo only: change status and submit
- [ ] Status change response returns `beforeStatus` and `afterStatus`

## 3. Board + Quality-Doc Routes
- [ ] Open `게시판`
- [ ] Board keyword=`Demo`, click `조회`
- [ ] Board list returns seeded posts
- [ ] Click one post title
- [ ] Route changes to `/board/:postId`
- [ ] Board detail returns content
- [ ] If attachment button exists, click it and confirm route changes to `/files/:fileId`
- [ ] Go back and create a board post
- [ ] New post creation succeeds and route moves to its detail page
- [ ] Open `품질 문서`
- [ ] Leave status blank, keyword=`Demo`, click `조회`
- [ ] Quality-doc list returns seeded documents
- [ ] Click `상세 / ACK`
- [ ] Route changes to `/quality-docs/:documentId`
- [ ] Open quality-doc register form and create one document
- [ ] For full feature demo only: ACK action succeeds

## 4. Inventory + File + Report Routes
- [ ] Open `재고 현황`
- [ ] Search with `ITEM-001`, `WH-01`
- [ ] Inventory balance list returns rows
- [ ] Click `이력 조회`
- [ ] Route changes to `/inventory/:itemCode/:warehouseCode`
- [ ] Inventory detail page shows balance and movement rows
- [ ] Open inventory adjustment form
- [ ] Submit one quantity adjustment
- [ ] Success response shows `resultingQuantity`
- [ ] Open `보고서 생성`
- [ ] Create a report job
- [ ] Click `상세 페이지 이동` or a `다시 조회` row button
- [ ] Route changes to `/reports/:jobId`
- [ ] Report detail returns current status
- [ ] If `outputFileId` exists, click it
- [ ] Route changes to `/files/:fileId`
- [ ] File detail page returns metadata

## 5. Cutover Runner
- [ ] `Cutover Runner` section visible
- [ ] Scenario runner button is clickable
- [ ] Integrated P0 run returns success summary or green result state

## Fail Conditions
Mark the demo as failed immediately if any of the following appears:
- [ ] Browser shows CORS error
- [ ] Browser shows 5xx gateway error
- [ ] Login fails with correct credentials
- [ ] Any section renders but returns empty/failed result for seeded path
- [ ] Order-Lot write action fails while write-open policy is enabled

## Evidence To Capture
- [ ] Browser screenshot: Login + Member route success
- [ ] Browser screenshot: Order route success
- [ ] Browser screenshot: Board + Quality-Doc route success
- [ ] Browser screenshot: Inventory + File + Report route success
- [ ] Browser screenshot: Cutover Runner success
- [ ] Demo seed summary file path captured from `scripts/seed-demo-data.ps1`
- [ ] Optional: devtools network screenshot for proxied `/api/*` call
