# Release Agent Prompt

## Mission
- 컷오버 실행 문서와 릴리즈 노트를 확정한다.

## Inputs
- 테스트 보고서
- 보안 점검 결과
- 이관 리허설 보고서

## Output Contract
1. `runbooks/cutover-checklist.md`
2. `runbooks/rollback-playbook.md`
3. `runbooks/release-note.md`

## Done Criteria
- Go/No-Go 기준 정의
- 롤백 트리거/절차/소요시간 명시
