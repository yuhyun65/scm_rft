# Browser Click Test Checklist

## Preconditions
- Backend started with `docker compose` actual-topology stack
- Demo data seeded with `smoke-gateway-auth-member-e2e.ps1`
- Frontend dev server started with `scripts/frontend-dev.ps1`
- Browser open at `http://localhost:5173`

## Login Credentials
- User demo: `smoke-user / password`
- Admin demo: `smoke-admin / password`

## 1. Auth + Member
- [ ] Login card visible
- [ ] Login ID defaults to `smoke-user`
- [ ] Password defaults to `password`
- [ ] Click `Login`
- [ ] `Login Response` shows `accessToken`, `memberId`, `roles`
- [ ] Click `Verify Token`
- [ ] `Verify Response` shows `active=true`
- [ ] Enter `smoke-user` in `Member ID`
- [ ] Click `Get Member`
- [ ] `Member Response` shows `memberId=smoke-user`
- [ ] In `Member Search`, keyword=`smoke`, status=`ACTIVE`
- [ ] Click `Search Members`
- [ ] `Search Response` shows `smoke-user` and `smoke-admin`

## 2. Order-Lot
- [ ] `Order-Lot P0 UI MVP` section visible
- [ ] Search orders with seeded keyword/order id if prefilled
- [ ] Click order search action
- [ ] Order list returns at least one record
- [ ] Open one order detail
- [ ] Open one lot detail
- [ ] For full feature demo only: change order status and submit
- [ ] Status change response returns `beforeStatus` and `afterStatus`

## 3. Board + Quality-Doc
- [ ] `Board + Quality-Doc UI MVP` section visible
- [ ] Board list returns seeded post
- [ ] Board detail returns content
- [ ] For full feature demo only: create board post succeeds
- [ ] Quality-doc list returns seeded document
- [ ] Quality-doc detail returns document metadata
- [ ] For full feature demo only: ACK action succeeds

## 4. Inventory + File + Report
- [ ] `Inventory + File + Report UI MVP` section visible
- [ ] Inventory balance search returns rows
- [ ] Inventory movement search returns rows
- [ ] For full feature demo only: file register succeeds
- [ ] File detail read succeeds
- [ ] For full feature demo only: report job create succeeds
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
- [ ] Optional: devtools network screenshot for proxied `/api/*` call
