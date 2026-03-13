# Production Deployment Topology

## Scope
- Baseline branch: `feature/to-be-dev-env-bootstrap`
- Runtime baseline: `f6528a5c3379c696169fcea64458398f230e1acd`
- Primary startup reference: `scripts/prod-up.ps1`, `scripts/prod-orchestration-common.ps1`

## 1) Runtime Topology
```text
Users / Browser
  -> Gateway (18080)
    -> Auth (8081)
    -> Member (8082)
    -> Board (8083) -> File (8087)
    -> Quality-Doc (8084)
    -> Order-Lot (8085)
    -> Inventory (8086)
    -> Report (8088)

All domain services
  -> Shared SQL Server

Ops / SRE
  -> Grafana / Prometheus / Loki / Tempo
  -> RabbitMQ (for platform/event readiness)
  -> Redis (for platform/runtime readiness)
```

## 2) Service Startup Order
| Order | Service | Port | Health URI | Depends On |
|---:|---|---:|---|---|
| 1 | auth | 8081 | `http://localhost:8081/actuator/health` | DB |
| 2 | member | 8082 | `http://localhost:8082/actuator/health` | DB, auth contract |
| 3 | file | 8087 | `http://localhost:8087/actuator/health` | DB |
| 4 | board | 8083 | `http://localhost:8083/actuator/health` | DB, file URL |
| 5 | quality-doc | 8084 | `http://localhost:8084/actuator/health` | DB |
| 6 | order-lot | 8085 | `http://localhost:8085/actuator/health` | DB |
| 7 | inventory | 8086 | `http://localhost:8086/actuator/health` | DB |
| 8 | report | 8088 | `http://localhost:8088/actuator/health` | DB |
| 9 | gateway | 18080 | `http://localhost:18080/actuator/health` | all upstream route targets, auth verify URI |

## 3) Infrastructure Nodes
| Component | Recommended Role | Notes |
|---|---|---|
| SQL Server | dedicated DB host or managed SQL | shared runtime DB, backup before cutover |
| Gateway host | edge / API entrypoint | external traffic ingress, emergency stop policy owner |
| App hosts | app runtime tier | 9 JVM processes or equivalent service units |
| RabbitMQ | shared infra | currently readiness/ops component, keep credentialed |
| Redis | shared infra | currently readiness/ops component, reserve managed instance |
| Observability stack | ops tier | Grafana / Prometheus / Loki / Tempo |

## 4) Network / Firewall Matrix
| Source | Target | Port | Purpose |
|---|---|---:|---|
| Client / office network | gateway host | 18080 | primary API ingress |
| gateway | auth | 8081 | token verify / auth APIs |
| gateway | member | 8082 | member APIs |
| gateway | board | 8083 | board APIs |
| gateway | quality-doc | 8084 | quality-doc APIs |
| gateway | order-lot | 8085 | order-lot APIs |
| gateway | inventory | 8086 | inventory APIs |
| gateway | file | 8087 | file APIs |
| gateway | report | 8088 | report APIs |
| all services | SQL Server | 1433 | shared DB |
| ops network | Grafana | 3000 | dashboard access |
| Prometheus | services | actuator/prometheus | metrics scrape |
| Loki/Tempo agents | services | app logs/traces | observability ingest |

## 5) Ownership Model
| Area | Primary Owner | Backup |
|---|---|---|
| Gateway policy / ingress | Dev Owner | Ops Owner |
| App JVM runtime | Dev Owner | Ops Owner |
| SQL Server / backup / restore | DBA | Dev Owner |
| Observability / dashboards / alerts | Ops Owner | Dev Owner |
| Secret manager / env rendering | Ops Owner | Dev Owner |

## 6) Deployment Mode Recommendation
1. Use one gateway host or service group fronted by the production ingress.
2. Run the 8 backend services under the `prod` profile with `scripts/prod-up.ps1` ordering as the operational baseline.
3. Keep SQL Server outside the app host lifecycle.
4. Keep Grafana/Prometheus/Loki/Tempo reachable from the ops network only.
5. Treat Redis/RabbitMQ credentials as production secrets even if current code usage is limited.

## 7) Verification Commands
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\check-prod-secrets.ps1 -EnvFile .env.production
powershell -ExecutionPolicy Bypass -File .\scripts\prod-up.ps1 -RunId SCM-OPS-VERIFY -EnvFile .env.production -StopExistingPorts
```
