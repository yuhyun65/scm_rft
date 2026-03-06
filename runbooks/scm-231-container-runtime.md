# SCM-231 Container Runtime Runbook

## Purpose
Build deployable images for 9 services and verify runtime health.

Services:
- auth
- member
- board
- quality-doc
- order-lot
- inventory
- file
- report
- gateway

## Prerequisites
- Docker command available
- Base branch synced
- `.env.staging` exists with required secrets

## Service Ports
| Service | Port | Health Endpoint |
|---|---:|---|
| auth | 8081 | `/actuator/health` |
| member | 8082 | `/actuator/health` |
| board | 8083 | `/actuator/health` |
| quality-doc | 8084 | `/actuator/health` |
| order-lot | 8085 | `/actuator/health` |
| inventory | 8086 | `/actuator/health` |
| file | 8087 | `/actuator/health` |
| report | 8088 | `/actuator/health` |
| gateway | 18080 | `/actuator/health` |

## Steps

### 1) Build Images
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\scm231-build-images.ps1 -Tag "scm231-r1"
```

Artifacts:
- `runbooks/evidence/SCM-231/docker-build-*.log`
- `runbooks/evidence/SCM-231/image-build-summary.md`

### 2) Start Services
Use the existing local service startup method used by this project (compose or bootRun background).

### 3) Run Health Check
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
powershell -ExecutionPolicy Bypass -File .\scripts\scm231-health-check.ps1
```

Artifacts:
- `runbooks/evidence/SCM-231/health-check-summary.md`
- `runbooks/evidence/SCM-231/health-check-summary.json`

## DoD
- Image build: `9/9 PASS`
- Runtime health: `9/9 UP`
- Evidence attached in PR comment:
  - `runbooks/evidence/SCM-231/image-build-summary.md`
  - `runbooks/evidence/SCM-231/health-check-summary.md`
