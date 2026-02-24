## Summary
- 

## 변경 범위
- 

## 리스크
- 

## 테스트 결과
- 

## 롤백 영향
- 

## Agentic AI Loop
- [ ] Architect 완료 (ADR + OpenAPI 초안)
- [ ] Build 완료 (구현 + 마이그레이션 코드)
- [ ] Test 완료 (테스트 코드 + 테스트 보고)
- [ ] Security 완료 (보안 체크리스트)
- [ ] Migration 완료 (Dry-run 리포트)
- [ ] Release 완료 (컷오버/롤백/릴리즈노트)

## Required Artifacts
- [ ] OpenAPI spec (`shared/contracts/*.openapi.yaml` or run artifacts)
- [ ] ADR (`doc/adr/*.md` or run artifacts)
- [ ] Migration report (`migration/reports/*.md` or run artifacts)
- [ ] Cutover checklist (`runbooks/cutover-checklist.md` or run artifacts)
- [ ] Rollback playbook (`runbooks/rollback-playbook.md` or run artifacts)

## Validation
- [ ] `powershell -ExecutionPolicy Bypass -File .\scripts\check-prereqs.ps1`
- [ ] `powershell -ExecutionPolicy Bypass -File .\scripts\agentic-validate-run.ps1 -RunDir <run_dir>`
- [ ] `powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate build`
- [ ] `powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate unit-integration-test`
