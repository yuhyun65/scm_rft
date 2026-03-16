# Production Env and Secrets Inventory

## Scope
- Baseline branch: `feature/to-be-dev-env-bootstrap`
- Runtime baseline: `e464c2084eded932aeb07cb51300a67c19ecf62d`
- Release tag: `v2026.03.16-scm-rft-operational-go`
- Validation script: scripts/check-prod-secrets.ps1
- Target env file name: .env.production (must remain untracked)

## Rules
1. .env.production must not be committed.
2. Runtime application secrets and infra secrets must be sourced from the production secret manager first, then rendered into the deploy host only for execution.
3. Placeholder/default values from dev or staging are prohibited in production.
4. Any change to a required key must update this inventory and re-run check-prod-secrets.ps1.

## 1) Runtime Application Keys
| Key | Scope | Required | Purpose | Source of Truth |
|---|---|---|---|---|
| SCM_DB_URL | all 8 services | Yes | shared SQL Server JDBC URL | secret manager |
| SCM_DB_USER | all 8 services | Yes | DB login user | secret manager |
| SCM_DB_PASSWORD | all 8 services | Yes | DB login password | secret manager |
| SCM_DB_DRIVER | all 8 services | Yes | JDBC driver class | deploy config |
| SCM_FLYWAY_ENABLED | all 8 services | Yes | enable migration in prod profile | deploy config |
| SCM_FLYWAY_LOCATIONS | all 8 services | Yes | Flyway locations | deploy config |
| SCM_FLYWAY_TABLE | all 8 services | Yes | Flyway table name | deploy config |
| SCM_AUTH_JWT_SECRET | auth | Yes | JWT signing key, length >= 32 | secret manager |
| SCM_AUTH_JWT_ISSUER | auth | Yes | token issuer | deploy config |
| SCM_AUTH_ACCESS_TOKEN_EXP_SECONDS | auth | Yes | access token TTL | deploy config |
| SCM_AUTH_LOGIN_MAX_FAILED_ATTEMPTS | auth | Yes | lockout threshold | deploy config |
| SCM_AUTH_LOGIN_LOCK_MINUTES | auth | Yes | lockout duration | deploy config |
| BOARD_FILE_SERVICE_BASE_URL | board | Yes | file service base URL | deploy config |
| GATEWAY_POLICY_PATH | gateway | Yes | route policy file path | deploy config |
| GATEWAY_AUTH_VERIFY_URI | gateway | Yes | auth token verify endpoint | deploy config |
| GATEWAY_AUTH_VERIFY_TIMEOUT_MS | gateway | Yes | auth verify timeout | deploy config |
| GATEWAY_AUTH_CB_SLIDING_WINDOW_SIZE | gateway | Yes | auth circuit breaker window | deploy config |
| GATEWAY_AUTH_CB_MIN_CALLS | gateway | Yes | auth circuit breaker min calls | deploy config |
| GATEWAY_AUTH_CB_FAILURE_RATE_THRESHOLD | gateway | Yes | auth circuit breaker fail rate | deploy config |
| GATEWAY_AUTH_CB_WAIT_OPEN_MS | gateway | Yes | auth circuit breaker open wait | deploy config |
| GATEWAY_AUTH_CB_HALF_OPEN_CALLS | gateway | Yes | auth circuit breaker half-open calls | deploy config |
| GATEWAY_EMERGENCY_STOP_ENABLED | gateway | Yes | emergency traffic stop flag | deploy config |
| GATEWAY_EMERGENCY_STOP_STATUS | gateway | Yes | emergency stop status code | deploy config |

## 2) Infrastructure / Platform Keys
| Key | Scope | Required | Purpose | Source of Truth |
|---|---|---|---|---|
| MSSQL_SA_PASSWORD | SQL Server host/container | Yes | SQL Server admin password | secret manager |
| RABBITMQ_DEFAULT_USER | broker | Yes | broker admin/app user | secret manager |
| RABBITMQ_DEFAULT_PASS | broker | Yes | broker admin/app password | secret manager |
| GRAFANA_ADMIN_USER | observability | Yes | Grafana admin user | secret manager |
| GRAFANA_ADMIN_PASSWORD | observability | Yes | Grafana admin password | secret manager |
| TZ | infra/common | Recommended | timezone consistency | deploy config |

## 3) Ownership
| Area | Owner | Verification |
|---|---|---|
| DB connection + flyway | DBA / Dev Owner | app startup + migration dry-run |
| JWT + auth lock policy | Dev Owner | auth health + login smoke |
| Gateway auth/cutover policy | Dev Owner / Ops | gateway health + policy smoke |
| Board -> file integration URL | Dev Owner | board create/list smoke |
| Broker / observability admin creds | Ops Owner | service connect + dashboard login |

## 4) Validation Commands
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\check-prod-secrets.ps1 -EnvFile .env.production
```

```powershell
git -C C:\Users\CMN-091\projects\SCM_RFT ls-files .env.production
# expected: no output
```

## 5) Deployment Notes
- Production should not reuse .env, .env.staging, or any dev/staging passwords.
- SCM_DB_URL should reference the production database only after backup is completed.
- GATEWAY_POLICY_PATH must point to the production-approved policy file, not local E2E policy examples.
- If Redis or additional external services are introduced later, add them here before deployment.
