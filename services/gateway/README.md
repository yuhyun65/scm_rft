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
- 환경변수로 재정의:
  - `GATEWAY_POLICY_PATH`
  - `GATEWAY_EMERGENCY_STOP_ENABLED`
  - `GATEWAY_EMERGENCY_STOP_STATUS`
