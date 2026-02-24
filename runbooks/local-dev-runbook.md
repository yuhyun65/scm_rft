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
