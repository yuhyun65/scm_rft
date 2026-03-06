# SCM-231 Containerization Kickoff

- Issue: `#44`
- Branch: `feature/scm-231-service-containerization`
- Base: `feature/to-be-dev-env-bootstrap`
- Owner: `CMN-091 + Codex`
- Date: `2026-03-06`

## Goal
8개 서비스(`auth/member/board/quality-doc/order-lot/inventory/file/report`)와 `gateway`의 배포 가능한 컨테이너 런타임 산출물을 고정한다.

## Scope
- 각 서비스 Dockerfile/실행 파라미터 점검 및 누락 보강
- 이미지 빌드/태깅/로컬 실행 명령 표준화
- health check/포트/필수 env 계약 고정
- 증적 경로 고정: `runbooks/evidence/SCM-231/`

## Out of Scope
- 서비스 비즈니스 로직 변경
- DB 스키마 변경
- 릴리즈 태그 발행

## Execution Checklist
- [ ] 서비스별 Dockerfile 존재/동작 점검 (`services/*/Dockerfile`)
- [ ] 공통 이미지 빌드 스크립트 작성 (`scripts/scm231-build-images.ps1`)
- [ ] 서비스별 health check 검증 스크립트 작성 (`scripts/scm231-health-check.ps1`)
- [ ] 도커 컴포즈 배포 프로파일 문서화 (`runbooks/scm-231-container-runtime.md`)
- [ ] 로컬 게이트 실행 및 증적 저장 (build, unit-integration-test, contract-test, smoke-test, migration-dry-run)
- [ ] PR 코멘트에 증적 링크 첨부

## DoD (Measured)
- 이미지 빌드 성공: `9/9` (`8 services + gateway`)
- health check 성공: `9/9` (`/actuator/health == UP`)
- 게이트: `5/5 PASS`, `[FAIL]=0`, `[SKIP]=0`
- 증적 파일: `runbooks/evidence/SCM-231/*` 생성 완료

## Start Commands
```powershell
Set-Location C:\Users\CMN-091\projects\SCM_RFT
git checkout feature/scm-231-service-containerization
```
