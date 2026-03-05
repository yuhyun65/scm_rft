# SCM_RFT 실운영 전환 Go 실행계획 (Issue/PR 단위)

기준일: 2026-03-05  
기준 브랜치: `feature/to-be-dev-env-bootstrap`  
원칙: `Issue 1개 = PR 1개 = 전용 브랜치 1개`

## 1. 최종 Go 판정 기준
- 8개 서비스 운영 배포 단위 확정(이미지/기동/헬스체크) 100%
- 운영 시크릿 외부화 완료(기본값/하드코딩 0건)
- 운영 관측/알람/장애대응 시나리오 검증 PASS
- 마이그레이션/롤백 리허설(운영 토폴로지 기준) PASS
- 최종 7게이트 무스킵 PASS + 컷오버 체크리스트/서명 완료

## 2. 실행 순서 (Issue/PR)

| 순서 | Issue ID | 브랜치 | PR 제목 | 핵심 작업 | 완료조건(DoD) | 선행 |
|---|---|---|---|---|---|---|
| 1 | SCM-230 | `feature/scm-230-release-baseline-lock` | `chore(scm-230): lock production release baseline` | `main` 릴리스 기준선 확정, 브랜치 정책/보호 규칙 반영, 릴리스 태그 기준 문서화 | 기준 브랜치 1개 확정, 릴리스 기준 커밋/태그 규칙 문서화, 브랜치 보호 규칙 적용 | 없음 |
| 2 | SCM-231 | `feature/scm-231-service-containerization` | `feat(scm-231): add deployable runtime artifacts for 8 services` | 8개 서비스 Dockerfile/이미지 빌드 정의, 공통 런타임 엔트리포인트 표준화 | 8/8 서비스 이미지 빌드 성공, 컨테이너 헬스 `UP` 100%, 기동 실패 0건 | SCM-230 |
| 3 | SCM-232 | `feature/scm-232-prod-config-secrets` | `security(scm-232): externalize production secrets and remove defaults` | 운영 프로파일 분리, JWT/DB/관리자 계정 기본값 제거, 시크릿 주입 경로 표준화 | 운영 설정파일 내 기본 시크릿 0건, secret scan High 0건, 인증/DB 연결 성공률 100% | SCM-231 |
| 4 | SCM-233 | `feature/scm-233-prod-deploy-orchestration` | `feat(scm-233): add production deployment orchestration scripts` | 운영 기동/종료/롤링재기동 스크립트, 서비스 의존순서/포트/환경변수 템플릿화 | 운영 모드 전체 기동 성공, 재기동 후 헬스 복구 <= 5분, 실패 재현 0건 | SCM-232 |
| 5 | SCM-234 | `feature/scm-234-observability-alerting` | `feat(scm-234): harden observability dashboards and alerts` | SLO 기반 대시보드/알람 룰 보강, 주요 지표 임계치 운영값 확정 | 주요 알람 테스트 100% 수신, p95/p99/오류율/RabbitMQ/DB 지표 수집 100% | SCM-233 |
| 6 | SCM-235 | `feature/scm-235-security-hardening-freeze` | `security(scm-235): close high-risk findings and freeze report` | 보안 점검 결과 동결, High 이상 0건 보장, 운영 보안 체크리스트 확정 | High/critical 0건, secret pattern 0건, 보안 체크리스트 승인 | SCM-232 |
| 7 | SCM-236 | `feature/scm-236-cutover-migration-automation` | `feat(scm-236): finalize cutover migration automation` | 컷오버용 migration 실행/검증 자동화, 도메인별 검증 SQL 최종 고정 | count mismatch 0, sum <= 0.1%, sample mismatch 0/200, status delta <= 1.0%p | SCM-233 |
| 8 | SCM-237 | `feature/scm-237-prod-topology-rehearsal-r4` | `feat(scm-237): execute production-topology rehearsal R4` | 운영 토폴로지 기준 리허설 1회(R4) + 롤백 실측 + 증적 수집 | 리허설 PASS, rollback <= 20분, rollback health(auth/member/gateway)=UP | SCM-234, SCM-235, SCM-236 |
| 9 | SCM-238 | `feature/scm-238-cutover-doc-freeze` | `docs(scm-238): freeze cutover checklist and release notes` | 컷오버 체크리스트/운영 런북/릴리즈노트 실측 기반 동결 | 템플릿 상태 0건, 근거 링크 100%, 승인자/시간/결정 기록 100% | SCM-237 |
| 10 | SCM-239 | `feature/scm-239-final-go-signoff` | `release(scm-239): final go-no-go signoff and release tag` | 최종 7게이트 무스킵, Go/No-Go 최종 승인, 릴리즈 태깅 | 7게이트 PASS(FAIL/SKIP 0), 최종 GO 서명 완료, 릴리즈 태그 생성 | SCM-238 |

## 3. 이슈/PR 생성 커맨드 템플릿

```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT

# 예시: SCM-230
gh issue create --title "SCM-230: lock production release baseline" --body "Release baseline lock for production Go."
git checkout feature/to-be-dev-env-bootstrap
git pull --ff-only
git checkout -b feature/scm-230-release-baseline-lock

# 작업 후
git add -A
git commit -m "chore(scm-230): lock production release baseline"
git push -u origin feature/scm-230-release-baseline-lock
gh pr create --base feature/to-be-dev-env-bootstrap --head feature/scm-230-release-baseline-lock --title "chore(scm-230): lock production release baseline" --body "Closes #<ISSUE_NO>"
```

## 4. 공통 게이트 (각 PR 필수)

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate build
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate unit-integration-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate contract-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate lint-static-analysis
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate security-scan
$env:SCM_ENABLE_GATEWAY_E2E_SMOKE="1"
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate smoke-test
powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate migration-dry-run
```

검증 규칙:
- exit code `0`만 PASS
- 게이트 로그 내 `[FAIL]` 0건
- 게이트 로그 내 `[SKIP]` 0건

## 5. 최종 릴리즈 체크포인트
- PR `SCM-230~239` 전부 `MERGED`
- Open High-risk 보안 이슈 `0`
- `runbooks/go-nogo-signoff.md` 최종 GO 서명 완료
- `doc/roadmap/progress.json` phase 상태 `completed` 일치
- 운영 배포 태그 생성 및 릴리즈 노트 게시 완료
