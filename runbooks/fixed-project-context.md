# Fixed Project Context (2026-02-26)

## Effective Date
- 2026-02-26

## Current Project State
- 설계서: `doc/scm_rft_design.md`
- 실행기록: `doc/QnA_보고서.md`
- 설계서 1~6장: 대부분 반영 완료
- 설계서 7장 권장 순서: phase-1 완료, phase-2~3 진행중, phase-4~5 미완료
- SCM-210/211: OpenAPI/PR 템플릿/런북 준비 완료, 실제 API 코드 구현은 미완료(health 수준)
- SCM-212: 매트릭스/정책 예시 작성 완료, route별 timeout/retry/cb는 런타임 파서 미반영(문서/주석 단계)
- SCM-213: R1 리포트 템플릿 + 도메인 SQL 8종 완료
- SCM-214: Go/No-Go signoff 문서 완성
- 워킹트리: 미커밋 산출물 누적 상태, PR 단위 분리 필요

## Fixed Rules
- 기준 브랜치: `feature/to-be-dev-env-bootstrap`
- 원칙: `Issue 1개 = PR 1개 = 전용 브랜치 1개`
- 필수 게이트: `build`, `unit-integration-test`, `contract-test`, `smoke-test`, `migration-dry-run`
- 산출물 경로:
  - `shared/contracts/`
  - `migration/reports/`
  - `runbooks/`
  - `doc/QnA_보고서.md`

## Output Principle (Locked)
- 답변은 실행 단계만 제시한다.
- 모호한 표현을 사용하지 않는다.
- 각 단계는 아래 4개를 포함한다.
  - command
  - file path
  - checkpoint
  - DoD(수치)
