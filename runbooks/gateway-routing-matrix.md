# Gateway Routing Matrix (SCM-212)

기준 정책 파일: `gateway/policies/cutover-isolation.yaml`

| Domain | Path Prefix | Target Service | Auth Required | Timeout (ms) | Retry (attempts) | Circuit Breaker | Rate-Limit (rps) |
|---|---|---|---|---:|---:|---|---:|
| auth | `/api/auth/**` | `http://auth:8081` | N | 3000 | 1 | enabled, failureRate=40, slowCallRate=50, waitOpen=10000 | 120 |
| member | `/api/member/**` | `http://member:8082` | Y | 5000 | 2 | enabled, failureRate=50, slowCallRate=50, waitOpen=10000 | 100 |
| file | `/api/file/**` | `http://file:8087` | Y | 8000 | 1 | enabled, failureRate=50, slowCallRate=50, waitOpen=10000 | 60 |
| inventory | `/api/inventory/**` | `http://inventory:8086` | Y | 5000 | 2 | enabled, failureRate=50, slowCallRate=50, waitOpen=10000 | 90 |
| report | `/api/report/**` | `http://report:8088` | Y | 12000 | 0 | enabled, failureRate=30, slowCallRate=50, waitOpen=10000 | 40 |
| order-lot (read) | `/api/order-lot/**` (`GET`) | `http://order-lot:8085` | Y | 10000 | 1 | enabled, failureRate=30, slowCallRate=50, waitOpen=10000 | 70 |
| order-lot (write) | `/api/order-lot/**` (`POST`,`PUT`,`PATCH`,`DELETE`) | `http://order-lot:8085` | Y | 10000 | 0 | enabled, failureRate=30, slowCallRate=50, waitOpen=10000 | 30 |
| board | `/api/board/**` | `http://board:8083` | Y | 5000 | 2 | enabled, failureRate=50, slowCallRate=50, waitOpen=10000 | 70 |
| quality-doc | `/api/quality-doc/**` | `http://quality-doc:8084` | Y | 6000 | 1 | enabled, failureRate=40, slowCallRate=50, waitOpen=10000 | 60 |

## 적용 규칙
- 기본값: timeout=5000ms, retry=2, circuit-breaker(failureRate=50, slowCallRate=50, waitOpen=10000), rate-limit=80rps.
- 도메인 override:
  - `auth`: timeout 3000, retry 1, rate-limit 120.
  - `report`: timeout 12000, retry 0, rate-limit 40.
  - `order-lot`: read/write 분리 정책 적용(write retry=0).

## 주의
- 현재 gateway 정책 로더는 route별 timeout/retry/circuit-breaker 필드를 직접 해석하지 않는다.
- runtime 적용은 `defaults` + `routes.rateLimitRps` + `writeProtection` 기반으로 동작한다.
- 본 매트릭스의 route별 timeout/retry/circuit-breaker 값은 SCM-212 구현 기준값으로 운영 문서에 고정한다.
