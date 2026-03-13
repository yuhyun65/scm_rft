# Hypercare and Rollback Monitoring Checklist

## Scope
Use this checklist from traffic-open time until the end of the agreed hypercare window.

## 1) Primary Metrics to Watch
| Metric | Threshold | Source |
|---|---:|---|
| 5xx error rate | `<=0.5%` | gateway logs / dashboard |
| 4xx error rate | `<=8.0%` (expected negatives only) | gateway logs / dashboard |
| p95 latency | `<=350ms` | gateway request metrics |
| p99 latency | `<=700ms` | gateway request metrics |
| RabbitMQ backlog | `ready<=1000`, `unacked<=500` | RabbitMQ management API |
| DB deadlock / timeout | `deadlock=0`, `timeout<=3/10m` | SQL / app logs |
| Auth failure rate | `<=3.0%` | auth route summary |
| Rollback health | `auth=UP, member=UP, gateway=UP` | actuator health |

## 2) Order-Lot Strict Watch
| Metric | Threshold | Source |
|---|---:|---|
| 5xx error rate | `<=0.2%` | order-lot status summary |
| p95 read latency | `<=250ms` | order-lot GET timing |
| p99 read latency | `<=450ms` | order-lot GET timing |
| write failure rate | `<=0.5%` | order-lot write summary |

## 3) Monitoring Checklist
- [ ] Grafana dashboard open and refreshed
- [ ] gateway error summary updated every 5 min
- [ ] auth failure summary updated every 5 min
- [ ] DB deadlock / timeout query checked every 10 min
- [ ] RabbitMQ queue depth checked every 5 min
- [ ] P0 user path re-smoked at least once during hypercare
- [ ] rollback owner remains on call until hypercare close

## 4) Immediate Rollback Triggers
Start rollback immediately if any of the following persists beyond the agreed observation window:
- [ ] any required service health becomes `DOWN`
- [ ] P0 flow fails for a real production user path
- [ ] 5xx error rate breaches threshold and does not recover
- [ ] p95/p99 latency breaches threshold and does not recover
- [ ] DB deadlock/timeout pattern indicates sustained write instability
- [ ] order-lot strict metrics breach and impact P0 flow

## 5) Rollback Action Stub
1. enable gateway emergency stop
2. execute DB restore from the latest verified backup
3. reopen legacy traffic path
4. record incident timeline, trigger, and recovery evidence

## 6) Hypercare Exit Criteria
- [ ] all metrics remain within threshold for the full window
- [ ] no unresolved P0 incident remains
- [ ] rollback not triggered
- [ ] final hypercare summary shared to Dev/Ops/QA
