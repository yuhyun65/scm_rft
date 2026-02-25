# Gateway Service

SCM_RFT API Gateway 실행체입니다.

## 역할
- `/api/*` 라우팅 진입점
- cutover 정책 기반 write 보호
- emergency stop(503) 제어

## 실행
```powershell
.\gradlew.bat :services:gateway:bootRun
```

## 정책 파일
- 기본 경로: `infra/gateway/policies/cutover-isolation.yaml`
- 로컬 E2E 경로: `infra/gateway/policies/local-auth-member-e2e.yaml`
- 환경변수로 재정의:
  - `GATEWAY_POLICY_PATH`
  - `GATEWAY_EMERGENCY_STOP_ENABLED`
  - `GATEWAY_EMERGENCY_STOP_STATUS`

로컬 Auth/Member E2E 시:
```powershell
$env:GATEWAY_POLICY_PATH="infra/gateway/policies/local-auth-member-e2e.yaml"
.\gradlew.bat :services:gateway:bootRun
```
