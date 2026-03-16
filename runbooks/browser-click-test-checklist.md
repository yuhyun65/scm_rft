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

## 1. Auth + Member
- [ ] Login card visible
- [ ] Login ID defaults to `smoke-user`
- [ ] Password defaults to `password`
- [ ] Click `Login`
- [ ] `Login Response` shows `accessToken`, `memberId`, `roles`
- [ ] Click `Verify Token`
- [ ] `Verify Response` shows `active=true`
- [ ] Enter `demo-buyer-001` in `Member ID`
- [ ] Click `Get Member`
- [ ] `Member Response` shows `memberId=demo-buyer-001`
- [ ] In `Member Search`, keyword=`demo`, status=`ACTIVE`
- [ ] Click `Search Members`
- [ ] `Search Response` shows multiple `demo-*` members

## 2. Order-Lot
- [ ] `Order-Lot P0 UI MVP` section visible
- [ ] In `Keyword`, enter `DEMO-ORDER`
- [ ] Click order search action
- [ ] Order list returns multiple records
- [ ] Set `Order ID=DEMO-ORDER-1002` and open detail
- [ ] Set `Lot ID=DEMO-LOT-1002-A` and open detail
- [ ] For full feature demo only: change `DEMO-ORDER-1002` status and submit
- [ ] Status change response returns `beforeStatus` and `afterStatus`

## 3. Board + Quality-Doc
- [ ] `Board + Quality-Doc UI MVP` section visible
- [ ] Board keyword=`Demo`, click search
- [ ] Board list returns multiple seeded posts
- [ ] Use `55555555-5555-5555-5555-000000000002` for detail lookup
- [ ] Board detail returns content
- [ ] For full feature demo only: create board post succeeds
- [ ] Leave quality-doc status blank, keyword=`Demo`, click search
- [ ] Quality-doc list returns seeded documents
- [ ] Use `66666666-6666-6666-6666-000000000002` for detail lookup
- [ ] For full feature demo only: ACK action succeeds

## 4. Inventory + File + Report
- [ ] `Inventory + File + Report UI MVP` section visible
- [ ] Inventory balance search with `ITEM-001` and `WH-01` returns rows
- [ ] Inventory movement search for the same item returns rows
- [ ] For full feature demo only: file register succeeds
- [ ] Use `44444444-4444-4444-4444-000000000003` for file detail read
- [ ] File detail read succeeds
- [ ] For full feature demo only: report job create succeeds
- [ ] Use `77777777-7777-7777-7777-000000000001` for report job detail
- [ ] Report job detail returns current status

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
- [ ] Browser screenshot: Auth + Member success
- [ ] Browser screenshot: Order-Lot success
- [ ] Browser screenshot: Board + Quality-Doc success
- [ ] Browser screenshot: Inventory + File + Report success
- [ ] Browser screenshot: Cutover Runner success
- [ ] Demo seed summary file path captured from `scripts/seed-demo-data.ps1`
- [ ] Optional: devtools network screenshot for proxied `/api/*` call
