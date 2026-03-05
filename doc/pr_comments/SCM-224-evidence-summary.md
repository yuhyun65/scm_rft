## SCM-224 증적 요약 (PR 코멘트용)

### 1) 변경 요약
- gateway 정책 로더 상대경로 해석 보강:
  - 상위 디렉터리까지 탐색하여 `infra/gateway/policies/...` 경로를 런타임에서 안정적으로 로드
- 회귀 테스트 추가:
  - `GatewayPolicyLoaderTests#resolvesConfiguredRelativePathFromParentDirectories`
- 운영 문서 반영:
  - `doc/QnA_보고서.md` 진행 로그 업데이트
  - `doc/roadmap/progress.json` 갱신

### 2) migration 산출물 포함/제외 기준
- 포함:
  - 코드/테스트/설계·운영 문서
  - 구조화 리포트(`.md`, `.state.json`) 중 팀 합의 산출물
- 제외:
  - 원시 SQL stdout 산출물 `migration/reports/*.out.txt` (재생성 가능, 노이즈)
- 정리 조치:
  - `.gitignore`에 `migration/reports/*.out.txt` 추가
  - 기존 untracked `R2/R3 *.out.txt` 삭제 완료

### 3) 게이트 증적
- build PASS:
  - `runbooks/evidence/SCM-224-20260305-R4/gate-build.log`
- unit-integration-test PASS:
  - `runbooks/evidence/SCM-224-20260305-R4/gate-unit-integration-test.log`
- contract-test PASS:
  - `runbooks/evidence/SCM-224-20260305-R4/gate-contract-test.log`
- lint-static-analysis PASS:
  - `runbooks/evidence/SCM-224-20260305-R4/gate-lint-static-analysis.log`
- security-scan PASS:
  - `runbooks/evidence/SCM-224-20260305-R4/gate-security-scan.log`
- migration-dry-run PASS:
  - `runbooks/evidence/SCM-224-20260305-R4/gate-migration-dry-run.log`
  - `migration/reports/validation-20260305-130216.md`
  - `migration/reports/dryrun-20260305-130215.state.json`
- smoke-test (gateway auth/member E2E) PASS:
  - `runbooks/evidence/SCM-224-20260305-R7/gate-smoke-test.log`

### 4) 원인/조치 검증 증적 (504/500 재발 방지)
- 정책 파일 로드 확인:
  - `runbooks/evidence/SCM-224-20260305-R7/gateway-policy-load-check.txt`
  - `Loaded gateway policy from file ...local-auth-member-e2e.yaml`
- login 정상 확인:
  - `runbooks/evidence/SCM-224-20260305-R7/gateway-login-check.txt`
  - `GW_LOGIN_OK`
- 런타임 로그:
  - `runbooks/evidence/SCM-224-20260305-R7/service-gateway.out.log`

### 5) 참고 파일
- `services/gateway/src/main/java/kr/co/computermate/scmrft/gateway/policy/GatewayPolicyLoader.java`
- `services/gateway/src/test/java/kr/co/computermate/scmrft/gateway/policy/GatewayPolicyLoaderTests.java`
- `doc/QnA_보고서.md`
