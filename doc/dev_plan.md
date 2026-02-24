# SCM_RFT 개발 추진 계획 (Dev Plan)

- 문서명: `dev_plan`
- 작성일: 2026-02-24
- 기준 문서: `doc/scm_rft_design.md` v1.3
- 기준 브랜치: `feature/to-be-dev-env-bootstrap`

## 1. 목적 대비 현재 점검 결과

### 1.1 점검 기준
- 설계서 1장 목적 3개 항목 기준
- 저장소 실자산(코드/스크립트/워크플로/문서) 기준
- `doc/roadmap/progress.json` 및 실행 스크립트 기준

### 1.2 종합 판정
- 상태: `기반 구축 완료, 본개발 착수 직전`
- 요약:
  - Phase 1(저장소/표준/자동화) 완료
  - Phase 2~5(서비스 구현/통합/리허설/컷오버) 미착수

### 1.3 목적별 달성도

| 설계서 목적 | 현재 상태 | 달성도(평가) | 근거 |
|---|---|---:|---|
| Big-Bang 방식 MSA 전환 | 미착수(구현 전) | 10% | `services/*` 실코드 부재(README 중심), 계약 초안 일부만 존재 |
| 개발환경 표준화/품질 자동화/보안 기본값 선행 | 기반 완료 | 75% | toolchain lock, dev/staging compose, CI gate workflow, dry-run/검증 스크립트 구축 |
| 개발자+Codex+Agentic AI 체계 운영 | 프레임워크 구축 완료, 운영 미착수 | 60% | `agentic/*` 및 스크립트 준비 완료, `agentic/runs` 실운영 산출물 없음 |

### 1.4 완료된 핵심 자산
- 표준 런타임/버전 고정: `toolchain.lock.json`, `.java-version`, `.nvmrc`, `.node-version`
- 로컬/스테이징 환경: `docker-compose.yml`, `docker-compose.staging.yml`, `scripts/dev-*.ps1`, `scripts/staging-*.ps1`
- GitHub 운영 표준: PR 템플릿, PR 정책, CI 게이트 워크플로
- 이관/검증/복구: `migration/scripts/dry-run.ps1`, `migration/verify/*`, `scripts/backup-db.ps1`, `scripts/restore-db.ps1`
- 리허설/컷오버 런북: `runbooks/*`
- 즉시실행 체크리스트 보강: OpenAPI 초안 + Flyway baseline + 리허설 일정 문서

### 1.5 주요 갭(완료 전 필수)
- 서비스 코드/빌드 체계 미구축:
  - Gradle wrapper/프로젝트 구조 없음
  - CI build/test/lint 게이트가 실코드 기준으로는 아직 실효성 제한
- 도메인별 API 계약 미완:
  - `file`, `board`, `quality-doc`, `inventory`, `report` 계약 미작성
- ADR/아키텍처 의사결정 로그 미작성
- 이관 매핑(AS-IS SP/테이블 -> TO-BE API/DB) 상세 명세 및 검증 리포트 미완
- 리허설 3회 실적/Go-NoGo 서명 이력 미존재

## 2. 최종 완료(Definition of Done)

## 2.1 제품/기능 완료
- 8개 서비스(auth/member/board/quality-doc/order-lot/inventory/file/report) 실행 가능
- API Gateway 정책으로 인증/권한/격리/긴급차단 적용 가능
- 핵심 사용자 시나리오(P0) end-to-end 통과

## 2.2 품질/보안 완료
- CI 7개 게이트 전부 `skip 없이` 통과
- 고위험 보안 이슈(High 이상) 미해결 0건
- 비밀정보 노출 패턴 0건

## 2.3 데이터/전환 완료
- 이관 리허설 3회 이상 완료
- 정합성 검증 임계치 충족:
  - 건수/합계 오차 0%
  - 샘플 검증 100%
- Go/No-Go 체크리스트 승인 및 컷오버/롤백 리허설 완료

## 3. 완료까지의 실행 방법 (Phase-by-Phase)

## 3.1 Phase 2: Auth/Member + Gateway (우선 착수)
- 목표:
  - 인증/회원 서비스 최소 실행 단위(MVP) 확보
  - 게이트웨이 경로/인증 연동 기준선 확정
- 작업:
  - `services/auth`, `services/member` Gradle 프로젝트 생성
  - OpenAPI -> Controller/DTO 스텁 생성 및 계약 테스트 연결
  - ADR 작성(`doc/adr/ADR-001-auth-member-gateway.md`)
  - `infra/gateway/policies`에 auth/member 라우팅 정책 구체화
- 종료 조건:
  - auth/member API smoke 통과
  - contract gate 통과
  - progress.json phase-2 done 갱신

## 3.2 Phase 3: OrderLot + File (핵심 리스크 구간)
- 목표:
  - 대형 SP 의존 도메인(Order/Lot)과 첨부(File) 경로를 우선 안정화
- 작업:
  - `order-lot`, `file` 서비스 MVP 구현
  - `shared/contracts/file.openapi.yaml` 추가 및 계약 테스트
  - AS-IS SP 매핑표 작성(입력/출력/에러코드)
  - migration mapping + 검증 리포트(`migration/reports/*orderlot*`, `*file*`) 생성
- 종료 조건:
  - 핵심 쓰기/조회 시나리오 smoke 통과
  - 이관 검증 리포트에서 Critical mismatch 0

## 3.3 Phase 4: Remaining Domains 통합
- 목표:
  - board/quality-doc/inventory/report 전 도메인 계약 및 통합 완성
- 작업:
  - 4개 도메인 OpenAPI 작성
  - 통합 테스트(도메인 간 호출 + 인증 + 파일 참조) 작성
  - `runbooks/test-report.md`, `runbooks/security-checklist.md` 실데이터로 업데이트
- 종료 조건:
  - 모든 서비스 계약서/기본 구현 존재
  - 통합 테스트 및 보안 점검 결과 승인

## 3.4 Phase 5: Rehearsal x3 + Big-Bang Cutover
- 목표:
  - 운영 유사 조건에서 전환 가능성 수치로 입증
- 작업:
  - `runbooks/cutover-rehearsal-schedule.md` 기준으로 R1~R3 수행
  - 각 회차별 증적 저장:
    - `migration/reports/validation-*.md`
    - 컷오버 체크리스트/이슈 로그/복구시간
  - Go/No-Go 회의 기록 및 최종 승인
- 종료 조건:
  - 리허설 3회 완료
  - Go/No-Go 체크리스트 서명
  - 컷오버 수행/롤백 절차 모두 실행 가능 상태

## 4. 운영 방식 (개발자 1인 + Codex + Agentic AI)

## 4.1 작업 단위
- 단위: `GitHub Issue 1개 = Agentic Run 1개 = PR 1개` 원칙
- PR 크기: 1~2일 내 리뷰 가능한 크기 유지

## 4.2 에이전트 실행 표준
1. Architect: 계약(OpenAPI)/ADR 초안 작성
2. Build: 코드/테스트 구현
3. Test: contract/integration/smoke 검증
4. Security: secret/SAST/dependency 확인
5. Migration: dry-run/validation 증적 생성
6. Release: runbook/release-note 업데이트

## 4.3 완료 증적 관리
- 위치:
  - 계약: `shared/contracts/`
  - ADR: `doc/adr/`
  - 이관 리포트: `migration/reports/`
  - 운영 증적: `runbooks/`
- 규칙:
  - PR 본문에 증적 링크 필수 첨부
  - `doc/roadmap/progress.json` 즉시 갱신

## 5. 제안 일정 (현 시점 기준)

| 주차 | 목표 | 산출물 |
|---|---|---|
| W1 | Phase 2 완료 | auth/member MVP, ADR-001, gateway 정책, contract/smoke pass |
| W2~W3 | Phase 3 완료 | order-lot/file MVP, file 계약, 이관 매핑/검증 리포트 |
| W4~W5 | Phase 4 완료 | 4개 도메인 계약+구현, 통합테스트, 보안/테스트 리포트 |
| W6~W7 | Phase 5 완료 | 리허설 3회 증적, Go/No-Go 승인, 컷오버 준비 완료 |

## 6. 즉시 실행 액션 (다음 작업 우선순위)
1. Gradle 멀티모듈 골격 생성(`services/auth`, `services/member`부터)
2. `file.openapi.yaml` 포함 누락 계약서 작성 시작
3. ADR-001(인증/회원/게이트웨이) 작성
4. CI 게이트를 `skip 없는 실제 실행` 기준으로 전환
5. `progress.json`을 실제 완료 상태(체크리스트 8 반영분 포함)로 업데이트
