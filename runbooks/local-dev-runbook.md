# Local Dev Runbook

## 1. 사전 점검
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check-prereqs.ps1
```

## 2. 인프라 실행
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev-up.ps1
```

## 3. 인프라 상태 확인
```powershell
docker compose ps
```

## 4. 인프라 종료
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev-down.ps1
```

## 5. 데이터까지 초기화
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev-down.ps1 -RemoveVolumes
```

## 6. Gateway Auth/Member E2E smoke
게이트웨이를 로컬 정책으로 실행한 뒤 E2E 스모크를 수행합니다.

사전 조건(터미널 1 - auth):

```powershell
$env:SCM_DB_URL="jdbc:sqlserver://localhost:1433;databaseName=MES_HI;encrypt=true;trustServerCertificate=true"
$env:SCM_DB_USER="sa"
$env:SCM_DB_PASSWORD="<MSSQL_SA_PASSWORD>"
$env:SCM_DB_DRIVER="com.microsoft.sqlserver.jdbc.SQLServerDriver"
$env:SCM_AUTH_JWT_SECRET="<32+ char secret>"
.\gradlew.bat :services:auth:bootRun
```

사전 조건(터미널 2 - member):

```powershell
$env:SCM_DB_URL="jdbc:sqlserver://localhost:1433;databaseName=MES_HI;encrypt=true;trustServerCertificate=true"
$env:SCM_DB_USER="sa"
$env:SCM_DB_PASSWORD="<MSSQL_SA_PASSWORD>"
$env:SCM_DB_DRIVER="com.microsoft.sqlserver.jdbc.SQLServerDriver"
.\gradlew.bat :services:member:bootRun
```

게이트웨이(터미널 3):

```powershell
$env:GATEWAY_POLICY_PATH="infra/gateway/policies/local-auth-member-e2e.yaml"
.\gradlew.bat :services:gateway:bootRun
```

다른 터미널에서:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\smoke-gateway-auth-member-e2e.ps1
```
