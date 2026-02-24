# Agentic AI Environment

`scm_rft_design.md` 4장(Codex + Agentic AI 적용 추진 체계)을 실행 가능한 형태로 구성한 운영 디렉터리입니다.

## 구성
- `agents.yaml`: 에이전트 역할/입출력/완료조건 정의
- `prompts/`: 에이전트별 작업 프롬프트 템플릿
- `templates/`: 필수 산출물 템플릿
- `runs/`: 실행 단위(run) 결과물 저장 경로

## 기본 실행 흐름
1. run 생성
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\agentic-new-run.ps1 -IssueId SCM-001 -Service auth
```

2. 단계 상태 업데이트
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\agentic-update-step.ps1 -RunDir .\agentic\runs\SCM-001-20260224-210000 -Agent architect -Status done -Notes "API 계약 초안 완료"
```

3. 산출물 검증
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\agentic-validate-run.ps1 -RunDir .\agentic\runs\SCM-001-20260224-210000
```

## 필수 산출물 (설계서 4.3 반영)
- OpenAPI 명세/예시 payload
- ADR
- 이관 리허설 결과 리포트
- 컷오버 체크리스트
- 롤백 플레이북
