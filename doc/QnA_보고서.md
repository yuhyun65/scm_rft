# HISCM 전환 준비 Q&A 보고서

- 작성일: 2026-02-24
- 작성자: Codex
- 범위: 본 세션에서 사용자 프롬프트와 Codex 답변(결과) 정리

## Q&A 이력

### Q1. 모놀리스 SCM를 MSA로 리팩토링하기 위해 준비해야 할 사항을 정리해줘
- 사용자 프롬프트:
  - "지금부터 모놀리스 형태로 개발된 기존의 SCM시스템(저장소 :https://github.com/yuhyun65/scm_rft)을 MSA 형태로 리팩토링할 계획입니다. 진행을 위해 준비해야할 사항을 정리해줘"
- Codex 답변(결과):
  - Strangler(점진 전환) 전제를 두고 준비 항목을 제시.
  - 핵심 항목: 목표/성공지표 정의, AS-IS 인벤토리, 도메인 경계 설계, 데이터 분리 전략, 공통 플랫폼(API Gateway/관측성/CI-CD), 보안/품질 기준, 단계적 전환 산출물.

### Q2. Strangler가 아닌 빅뱅 방식으로 다시 정리해줘
- 사용자 프롬프트:
  - "Strangler(점진 전환) 방식이 아닌 빅뱅 방식으로 진행할 수있도록 다시정리해줘"
- Codex 답변(결과):
  - Big-Bang 전환 체크리스트로 재정리.
  - 핵심 항목: 범위 동결, 목표 아키텍처 고정, 데이터 이관 리허설(3회 이상), 품질 게이트, 컷오버 Runbook, Go/No-Go, 롤백 절차, 전환 타임라인(T-16주~T+4주).

### Q3. 1인 개발자 + Codex + GitHub + Agentic AI 기반의 최적 추진방법 정리
- 사용자 프롬프트:
  - "이프로젝트는 개발자 1인+CODEX가 함께 GITHUB를 활용하여 진행할 계획이며, AGENTIC AI를 체계적으로 활용할 계획입니다. 최적의 추진방법을 정리해줘"
- Codex 답변(결과):
  - Monorepo + Spec-First + 자동검증 강제 + 역할 분리 전략 제안.
  - 핵심 항목: 사람/AI 책임 분리, GitHub 템플릿/브랜치 보호, Plan→Build→Test→Review→Release 에이전트 루프, CI 필수 게이트, 데이터 이관 코드화, 주간 운영 리듬.

### Q4. GitLab legacy 저장소 분석 후 현재 시스템 분석 보고서 작성
- 사용자 프롬프트:
  - "https://gitlab.computermate.co.kr/mate/legacy 저장소를 분석하여 다음을 분석해서 현재 시스템 분석 보고서를 작성해줘"
- Codex 수행(중간):
  - 로컬 미러(bare repo) 기준으로 구조/코드/SQL/SP 정적 분석 수행.
  - 주요 확인 포인트: Controller/GetData/FileUpload/Config, xrw 화면 흐름, install 자산, SP 라우팅/테이블, 커밋 이력.

### Q5. 진행 확인
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - 분석 계속 진행 후 AS-IS 시스템 분석 보고서 최종 제시.

### Q6. 최종 분석 보고서 핵심 결과
- 사용자 프롬프트:
  - (Q4+Q5의 결과 요청 맥락)
- Codex 답변(결과 요약):
  - 시스템 성격: JSP/Servlet + XRW(ActiveX 의존) + SQL Server Stored Procedure 중심 레거시.
  - 구조 특성: 사실상 단일 진입 Controller 패턴, 업무 로직 다수가 대형 SP(특히 `sp_SCM_OrderManager`)에 집중.
  - 데이터/운영 특성: DB 중심 + 파일 업로드(`TRUSTUPLOADFILE`) + 클라이언트 로컬 MDB/ActiveX 설치 자산 의존.
  - 리스크: 하드코딩된 DB 정보, 동적 쿼리 조립 경로, 구형 보안 방식(MD5 계열/평문 전달 흔적), 테스트/빌드 자동화 부재.
  - 결론: 도메인 분해 가능성은 있으나 보안·운영·호환성 리스크가 높아 전환 전 표준화(계약/API/테스트/컷오버 준비)가 선행되어야 함.

### Q7. QnA_보고서.md 저장 요청 및 저장 경로 변경
- 사용자 프롬프트:
  - "QnA_보고서.md를 저장해줘"
  - "저장경로를 알려줘"
  - "C:\\Users\\CMN-091\\projects\\SCM_RFT\\doc에 저장"
- Codex 답변(결과):
  - Q&A 보고서를 지정 경로에 저장 완료.
  - 최종 저장 파일: `C:\\Users\\CMN-091\\projects\\SCM_RFT\\doc\\QnA_보고서.md`

### Q8. 원격 저장소 커밋/푸시 요청
- 사용자 프롬프트:
  - "원격저장소에 커밋/푸시해줘"
  - "예"
- Codex 답변(결과):
  - 별도 worktree를 사용해 안전하게 커밋/푸시 수행.
  - 커밋: `c398873` (`docs: add QnA report markdown`)
  - 푸시 대상: GitLab `origin/main`

### Q9. GitLab 저장소를 GitHub로 복사하고 연결 해제
- 사용자 프롬프트:
  - "https://gitlab.computermate.co.kr/mate/legacy.git를 https://github.com/yuhyun65/scm_rft로 복사해주고 연결를 끊어줘"
- Codex 답변(결과):
  - GitLab 기준 이력을 GitHub로 강제 동기화(`main` forced update).
  - `origin`(GitLab) 원격 제거 완료.
  - 원격 검증 결과 `github`만 남음.

### Q10. 임시 worktree 정리
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - 임시 worktree `C:\\Users\\CMN-091\\projects\\SCM_RFT\\legacy-wt` 제거 완료.
  - worktree 목록에 bare 저장소만 남도록 정리.

### Q11. SCM_RFT를 기본 개발 저장소로 동기화 설정
- 사용자 프롬프트:
  - "이제 모든 개발은 c:\\Users\\CMN-091\\projects\\SCM_RFT와 로컬 C:\\Users\\CMN-091\\projects\\SCM_RFT 저장소를 도아기화해서 진행할 수 있도록 해줘"
- Codex 답변(결과):
  - `SCM_RFT` 폴더를 일반 Git 저장소로 초기화.
  - `origin`을 GitHub(`https://github.com/yuhyun65/scm_rft.git`)로 연결.
  - `main` 브랜치를 `origin/main`과 동기화/추적 상태로 설정.
  - 상태 확인: `## main...origin/main` (clean)

### Q12. 백업 저장소 폴더 삭제
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - 백업 폴더 `C:\\Users\\CMN-091\\projects\\SCM_RFT\\legacy.git` 삭제 완료.
  - 삭제 후 저장소 정상 상태 유지 확인.

### Q13. 이후 진행 건의 Q&A 누적 기록 요청
- 사용자 프롬프트:
  - "지금부터는 진행상황을 프롬프트와 답변(결과) 한쌍이 진행되면 QnA_보고서.md에 계속해서 내용을 추가해줘"
- Codex 답변(결과):
  - 본 요청/응답 쌍부터 `QnA_보고서.md`에 누적 기록을 계속 추가하기로 반영.

### Q14. AS-IS 분석 기반 Big-Bang 리팩토링 설계서 작성 요청
- 사용자 프롬프트:
  - "이 내용을 기반으로 codex+agentic ai를 적용한 빅뱅방식의 scm 리팩토링 설계서(scm_rft_design)를 작성해줘"
- Codex 답변(결과):
  - `doc/scm_rft_design.md` 설계서 신규 작성 완료.
  - 포함 내용: 목표/범위, TO-BE 서비스 아키텍처, 서비스-DB-SP 매핑, 보안 개선, Big-Bang 이관/컷오버/롤백, Agentic AI 운영모델, GitHub/CI 규칙, 리스크 대응, 실행 로드맵.

### Q15. 기존 개발환경 분석 및 신규 최적 개발환경 제안 요청
- 사용자 프롬프트:
  - "기존 시스템의 개발환경을 분석하고 새로 개발하는 시스템의 최적 개발 환경을 제안해줘"
- Codex 답변(결과):
  - 기존 환경 분석 요약:
    - JSP/Servlet + XRW/ActiveX + SQL Server SP 중심 구조, 단일 컨트롤러 패턴
    - 빌드 도구 부재(`pom.xml`, `build.gradle` 없음), 수동 의존성(`WEB-INF/jar`) 관리
    - 하드코딩 설정/구형 실행환경 의존(Windows/IE/로컬 MDB/ActiveX)
  - 신규 최적 환경 제안 요약:
    - `Java 21 + Spring Boot 3.x + Gradle` 표준화
    - `React+TypeScript` 기반 웹 표준 UI로 ActiveX 제거
    - Docker Compose 로컬 스택(SQL Server/Redis/메시지브로커/관측성) + GitHub Actions CI 게이트
    - Codex+Agentic AI 역할 분리(Architect/Build/Test/Security/Release)로 1인 개발 생산성 극대화
    - Big-Bang 컷오버 대비 이관 리허설/롤백 자동화 환경 선구축

### Q16. 개발환경 분석/제안 내용을 `scm_rtf_design.md`에 반영 요청
- 사용자 프롬프트:
  - "이 내용을 scm_rtf_design.md에 반영해줘"
- Codex 답변(결과):
  - `doc/scm_rtf_design.md`를 v1.2로 갱신.
  - 반영 항목:
    - AS-IS 개발환경 분석 강화(기술구조, 개발/배포 방식, 보안/운영/생산성 리스크)
    - TO-BE 최적 개발환경 구체화(표준 런타임, 로컬 Compose, 저장소 구조, 테스트/보안/이관 체계)
    - Codex+Agentic AI 추진 체계 및 GitHub CI 게이트 명확화
    - Big-Bang 리허설/컷오버 환경 요구사항 및 즉시 실행 체크리스트 추가

### Q17. 파일명 정정(`scm_rft_design.md`) 및 오기 파일 삭제 요청
- 사용자 프롬프트:
  - " scm_rtf_design.md가 아니라  scm_rft_design.md가 맞는 파일입니다. scm_rft_design.md 내용을 반영하고 scm_rtf_design.md는 삭제해줘"
- Codex 답변(결과):
  - `doc/scm_rft_design.md`를 최신 설계 내용(v1.2)으로 갱신 반영.
  - 문서명 표기를 `scm_rft_design`으로 정정.
  - 오기 파일 `doc/scm_rtf_design.md` 삭제 완료.

### Q18. 커밋/푸시 진행 확인
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - `doc/scm_rft_design.md`와 `doc/QnA_보고서.md` 변경사항을 커밋.
  - 원격 저장소 `origin(main)`으로 푸시 완료.

### Q19. TO-BE 개발환경 제안 기준으로 개발환경 재구축 요청
- 사용자 프롬프트:
  - "scm_rft_design.md 파일의 내용중 3. 신규 시스템 최적 개발환경(TO-BE) 제안에 따라 개발환경을 다시 구축해줘"
- Codex 답변(결과):
  - TO-BE 기준의 로컬 개발환경 골격을 신규 구축:
    - 저장소 구조 추가: `services/`, `shared/`, `infra/`, `migration/`, `runbooks/`, `scripts/`
    - 로컬 인프라 추가: `docker-compose.yml`(SQL Server, Redis, RabbitMQ, Loki, Prometheus, Grafana, Tempo)
    - 관측 설정 추가: `infra/observability/*`
    - 실행 스크립트 추가: `scripts/check-prereqs.ps1`, `scripts/dev-up.ps1`, `scripts/dev-down.ps1`
    - 문서/가이드 갱신: `README.md`, `runbooks/local-dev-runbook.md`
  - 구성 검증:
    - `docker compose config` 정상 통과
    - 사전점검 결과: Docker/Compose/Node/Gradle 감지, Java는 17로 확인(목표는 21)
    - `scripts/dev-up.ps1` 실행 시 Docker Desktop daemon 미기동으로 중단됨(스크립트에 명확한 에러 안내 반영)

### Q20. 브랜치 기반 개발 요청
- 사용자 프롬프트:
  - "브랜치 레포를 만들어서 개발을 진행하고 싶어"
- Codex 답변(결과):
  - 전용 개발 브랜치 생성 완료: `feature/to-be-dev-env-bootstrap`
  - 이후 개발환경 재구축 작업을 해당 브랜치에서 진행하도록 전환.

### Q21. Docker 재실행/`dev-up`/Java21 업그레이드/버전 고정/커밋푸시 요청
- 사용자 프롬프트:
  - "다음 진행해줘

Docker Desktop 실행 후 dev-up.ps1 재실행
Java 21로 업그레이드(현재 17) 및 버전 고정 정책 적용
이 변경사항을 브랜치에 커밋/푸"
- Codex 답변(결과):
  - Docker Desktop 실행 후 `scripts/dev-up.ps1` 재실행 완료.
  - 로컬 인프라 기동 확인:
    - `sqlserver`, `redis`, `rabbitmq`, `loki`, `prometheus`, `grafana`, `tempo` 모두 `Up` 상태.
  - `tempo` 권한 오류 보정:
    - `docker-compose.yml`에서 `tempo`에 `user: "0:0"` 적용 및 볼륨 경로를 `/var/tempo`로 변경.
    - `infra/observability/tempo/tempo.yaml`의 storage 경로를 `/var/tempo/*`로 정정.
  - Java 21 업그레이드 완료:
    - Temurin JDK 21 설치(`C:\\Users\\CMN-091\\.jdks\\jdk-21.0.10+7`)
    - 사용자 환경변수 `JAVA_HOME`를 JDK 21로 설정.
  - 버전 고정 정책 적용:
    - `toolchain.lock.json` 추가(Java/Node/Gradle/Docker Compose 고정 버전 정의)
    - `.java-version`, `.nvmrc`, `.node-version` 추가
    - `scripts/use-toolchain.ps1` 추가(잠금 버전 세션 적용/영구 반영)
    - `scripts/check-prereqs.ps1` 개선(잠금 버전 대비 검증)
    - 검증 결과: Java/Node/Gradle/Docker Compose 모두 잠금 버전과 일치.

### Q22. PR 생성 진행 요청
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - 브랜치 `feature/to-be-dev-env-bootstrap`에서 `main` 대상으로 PR 생성 완료.
  - PR URL: `https://github.com/yuhyun65/scm_rft/pull/1`

### Q23. 설계서 4장 기준 Agentic AI 적용환경 구축 요청
- 사용자 프롬프트:
  - "다음은 scm_rft_design.md의 4. Codex + Agentic AI 적용 추진 체계에 따라 Agentic AI 적용환경을 만들어줘"
- Codex 답변(결과):
  - Agentic AI 운영 환경을 저장소에 신규 구축:
    - `agentic/` 디렉터리 신설 (`agents.yaml`, `prompts/*`, `templates/*`, `runs/.gitkeep`)
    - 에이전트 루프(Architect/Build/Test/Security/Migration/Release) 정의 및 산출물 계약 반영
    - 실행 스크립트 추가:
      - `scripts/agentic-new-run.ps1`
      - `scripts/agentic-update-step.ps1`
      - `scripts/agentic-validate-run.ps1`
    - PR 템플릿/CI 스모크 워크플로 추가:
      - `.github/PULL_REQUEST_TEMPLATE.md`
      - `.github/workflows/agentic-run-smoke.yml`
    - 산출물 기본 저장소 추가:
      - `doc/adr/README.md`
      - `shared/contracts/README.md`
      - `migration/reports/README.md`
      - `runbooks/cutover-checklist.md`, `runbooks/rollback-playbook.md`, `runbooks/release-note.md`, `runbooks/security-checklist.md`, `runbooks/test-report.md`
    - README/Makefile에 Agentic 명령 반영
  - 검증:
    - `agentic-new-run.ps1` 실행 성공
    - `agentic-update-step.ps1` 실행 성공
    - `agentic-validate-run.ps1` 실행 성공

### Q24. Agentic AI 적용환경 변경사항 커밋/푸시 요청
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - Agentic AI 적용환경 관련 변경사항을 브랜치에 커밋 후 원격으로 푸시.
  - 기존 PR(`#1`)에 최신 커밋 반영.

### Q25. 설계서 5장 기준 GitHub 운영 표준 반영 요청
- 사용자 프롬프트:
  - "다음은 scm_rft_design.md의 5. GitHub 운영 표준을 반영해줘"
- Codex 답변(결과):
  - GitHub 운영 표준을 저장소에 반영:
    - PR 템플릿 강화: `변경 범위`, `리스크`, `테스트 결과`, `롤백 영향` 섹션 추가
    - PR 정책 워크플로 추가: `.github/workflows/pr-policy.yml`
      - 브랜치 네이밍(`feature/*`, `fix/*`, `chore/*`) 검사
      - PR 본문 필수 섹션 검사
    - CI 게이트 워크플로 추가: `.github/workflows/ci-gates.yml`
      - build
      - unit/integration test
      - contract test
      - lint/static analysis
      - SAST + secret + dependency scan
      - migration dry-run
      - smoke test
    - 로컬/CI 공통 게이트 스크립트 추가: `scripts/ci-run-gate.ps1`
    - migration dry-run 기본 스크립트 추가: `migration/scripts/dry-run.ps1`
    - Makefile/README에 게이트 실행 명령 반영
  - 로컬 검증:
    - `ci-run-gate` 주요 게이트 실행 성공(build/test/lint는 현재 Gradle 프로젝트 미구성으로 skip 처리)
    - `smoke-test`에서 `docker compose config`와 Agentic run 검증 성공

### Q26. GitHub 운영 표준 반영 변경사항 커밋/푸시 요청
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - GitHub 운영 표준 반영 변경사항을 브랜치에 커밋 후 원격으로 푸시.
  - 기존 PR(`#1`)에 최신 커밋 반영.

### Q27. 설계서 6장(Big-Bang 전환 대응 환경 요구사항) 반영 요청
- 사용자 프롬프트:
  - "다음은 scm_rft_design.md의 6. Big-Bang 전환 대응 환경 요구사항을 반영해줘"
- Codex 답변(결과):
  - 6장 요구사항을 실행 가능한 자산으로 반영:
    - staging 리허설 환경:
      - `docker-compose.staging.yml`
      - `scripts/staging-up.ps1`, `scripts/staging-down.ps1`
      - `.env.staging.example`
    - 이관 재실행/검증:
      - `migration/scripts/dry-run.ps1`(state 파일 기반 resume 지원)
      - `migration/verify/validate-migration.ps1`
      - `migration/verify/config.sample.json`
      - `scripts/rehearsal-run.ps1`
    - 관측/게이트웨이/백업:
      - Grafana provisioning + cutover dashboard
      - `infra/gateway/policies/cutover-isolation.yaml`
      - `scripts/backup-db.ps1`, `scripts/restore-db.ps1`
      - `migration/backups/` 구조 추가
    - 운영 문서:
      - `runbooks/bigbang-rehearsal-runbook.md`
      - `runbooks/cutover-operations-runbook.md`
      - README/Makefile/설계서(6.3 구현 자산) 갱신
  - 검증:
    - `docker compose -f docker-compose.yml config` 성공
    - `docker compose -f docker-compose.staging.yml config` 성공
    - migration dry-run / validation / rehearsal-run(옵션) 성공
    - staging 환경 실제 기동(`staging-up`) 및 종료(`staging-down`) 성공

### Q28. 6장 반영 변경사항 커밋/푸시 요청
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - 6장 반영 변경사항을 브랜치에 커밋 후 원격으로 푸시.
  - 기존 PR(`#1`)에 최신 커밋 반영.

### Q29. 설계서 7장(권장 추진 순서) 반영 요청
- 사용자 프롬프트:
  - "scm_rft_design.md의 7. 권장 추진 순서 반영해줘"
- Codex 답변(결과):
  - 7장을 실행 가능한 운영체계로 반영:
    - 단계 문서 추가:
      - `doc/roadmap/phase-1-foundation.md`
      - `doc/roadmap/phase-2-auth-member-gateway.md`
      - `doc/roadmap/phase-3-orderlot-file.md`
      - `doc/roadmap/phase-4-remaining-domains.md`
      - `doc/roadmap/phase-5-rehearsal-cutover.md`
      - `doc/roadmap/README.md`
    - 진행 보드/리포트 추가:
      - `doc/roadmap/progress.json`
      - `scripts/roadmap-report.ps1`
    - GitHub 이슈 템플릿 추가:
      - `.github/ISSUE_TEMPLATE/phase-work-item.yml`
      - `.github/ISSUE_TEMPLATE/config.yml`
    - README/Makefile/설계서에 7장 운영 명령/연결 반영
  - 검증:
    - `scripts/roadmap-report.ps1` 실행 성공(phase별 진행률 출력 확인)

### Q30. 7장 반영 변경사항 커밋/푸시 요청
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - 7장 반영 변경사항을 브랜치에 커밋 후 원격으로 푸시.
  - 기존 PR(`#1`)에 최신 커밋 반영.

### Q31. 설계서 8장(즉시 실행 체크리스트) 반영 요청
- 사용자 프롬프트:
  - "scm_rft_design.md의 8. 즉시 실행 체크리스트 반영해줘"
- Codex 답변(결과):
  - 문서와 자산 상태를 점검한 뒤 8장 반영 작업에 착수.
  - 확인 결과:
    - 체크리스트 1/2/4 관련 자산은 이미 저장소에 존재
    - 체크리스트 3(OpenAPI/Flyway)과 5(리허설 일정 명시)는 보강 필요 상태

### Q32. 현재 작업폴더 확인 요청
- 사용자 프롬프트:
  - "현재 작업폴더가 c:\\Users\\CMN-091\\projects\\scm_rft로 알고 있는데 확인해줘"
- Codex 답변(결과):
  - 터미널에서 `Get-Location`으로 확인.
  - 실제 작업 경로는 `C:\\Users\\CMN-091\\projects\\SCM_RFT`로 확인(인식과 동일).

### Q33. 8장 반영 작업 계속 진행 요청
- 사용자 프롬프트:
  - "진행해줘"
- Codex 답변(결과):
  - `doc/scm_rft_design.md`를 v1.3으로 갱신하고 `8.1 구현 반영 자산` 섹션 추가.
  - 체크리스트 3번 반영:
    - OpenAPI 계약 초안 추가:
      - `shared/contracts/auth.openapi.yaml`
      - `shared/contracts/member.openapi.yaml`
      - `shared/contracts/order-lot.openapi.yaml`
    - Flyway baseline 추가:
      - `migration/flyway/README.md`
      - `migration/flyway/V1__baseline.sql`
  - 체크리스트 5번 반영:
    - 리허설 일정/Go-NoGo 기준 문서 추가:
      - `runbooks/cutover-rehearsal-schedule.md`
  - Q&A 누적 정책에 따라 본 이력(Q31~Q33)을 `QnA_보고서.md`에 이어서 반영.

### Q34. 8장 반영 결과 커밋/푸시 요청
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - 체크리스트 8 반영 변경사항과 Q&A 갱신분을 브랜치에 커밋.
  - 원격 `origin/feature/to-be-dev-env-bootstrap`로 푸시해 PR(`#1`)에 반영.

### Q35. 목적 대비 진행상황 점검 및 완료단계 추진계획 문서화 요청
- 사용자 프롬프트:
  - "scm_rft_design.md의 목적 대비 현재까지의 진행상황을 점검하고 최종 프로젝트 완려단계까지 진행방법을 정리해서 dev_plan.md로 작성해줘"
- Codex 답변(결과):
  - 설계서 목적(1장) 기준으로 현재 자산/로드맵/CI/서비스 코드 상태를 점검.
  - 판정 결과를 기반으로 완료 기준(Definition of Done), Phase 2~5 실행전략, 주차별 일정, 즉시 실행 우선순위를 정리한 계획 문서를 신규 작성:
    - `doc/dev_plan.md`
  - Q&A 누적 정책에 따라 본 요청/결과(Q35)까지 `QnA_보고서.md`에 반영.

### Q36. dev_plan 반영 결과 커밋/푸시 요청
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - `doc/dev_plan.md` 신규 파일과 `doc/QnA_보고서.md` 업데이트 내용을 브랜치에 커밋.
  - 원격 `origin/feature/to-be-dev-env-bootstrap`로 푸시해 PR(`#1`)에 반영.

### Q37. dev_plan 1.5 주요 갭의 실제 구현 가능화 요청
- 사용자 프롬프트:
  - "dev_plan.md의 1.5 주요 갭(완료 전 필수)을 실제 구현이 가능하도록 만들어줘"
- Codex 답변(결과):
  - 서비스 코드/빌드 체계 갭 보완:
    - Gradle 멀티모듈 골격 추가:
      - `settings.gradle`, `build.gradle`, `gradlew`, `gradlew.bat`, `gradle/wrapper/*`
      - `services/*/build.gradle`
    - 8개 서비스 Spring Boot 최소 실행 골격 추가:
      - `services/*/src/main/java/*Application.java`
      - `services/*/src/main/java/*HealthController.java`
      - `services/*/src/main/resources/application.yml`
      - `services/*/src/test/java/*ApplicationTests.java`
  - 도메인 계약 갭 보완:
    - 누락 OpenAPI 계약 추가:
      - `shared/contracts/file.openapi.yaml`
      - `shared/contracts/board.openapi.yaml`
      - `shared/contracts/quality-doc.openapi.yaml`
      - `shared/contracts/inventory.openapi.yaml`
      - `shared/contracts/report.openapi.yaml`
  - ADR 갭 보완:
    - `doc/adr/ADR-001-auth-member-gateway.md`
    - `doc/adr/ADR-002-orderlot-file-first.md`
  - 이관 매핑/검증 리포트 갭 보완:
    - `migration/mapping/legacy-sp-to-target-mapping.md`
    - `migration/templates/validation-report-template.md`
    - `scripts/new-migration-report.ps1`
  - 리허설/Go-NoGo 증적 갭 보완:
    - `runbooks/rehearsals/rehearsal-record-template.md`
    - `runbooks/rehearsals/README.md`
    - `runbooks/go-nogo-signoff.md`
    - `scripts/new-rehearsal-record.ps1`
  - 운영 문서/명령 동기화:
    - `doc/dev_plan.md` 1.5를 “구현 가능화 테이블”로 개편
    - `doc/roadmap/progress.json` 진행률 갱신(phase-2/3 in_progress)
    - `README.md`, `Makefile`, `services/README.md`, `migration/README.md`, `runbooks/README.md`, `runbooks/cutover-checklist.md`, `shared/contracts/README.md` 갱신
  - 검증 결과:
    - `contract-test` 통과 (8개 OpenAPI 검증)
    - `build` 게이트 통과 (8개 서비스 bootJar 포함)
    - `unit-integration-test` 게이트 통과
    - `lint-static-analysis` 게이트 통과
    - `smoke-test` 게이트 통과
    - `roadmap-report` 기준: phase-2 67%, phase-3 33%로 반영

### Q38. 1.5 구현 가능화 반영 결과 커밋/푸시 요청
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - 1.5 구현 가능화 관련 코드/문서/스크립트 변경사항을 브랜치에 커밋.
  - 원격 `origin/feature/to-be-dev-env-bootstrap`로 푸시해 PR(`#1`)에 반영.

### Q39. 제품/기능 구현 전 DB 스키마 선설계 필요 여부 검토 요청
- 사용자 프롬프트:
  - "이작업을 하려면 db 스키마를 먼저 설계해야 하는지 검토해줘"
- Codex 답변(결과):
  - 결론: 선설계 필요.
  - 단, 전체를 한 번에 고정하지 않고 `2.1 P0` 기능 기준 최소 스키마를 먼저 확정하는 방식으로 제안.
  - 기존 `V1__baseline.sql`이 `auth/member/order-lot/file` 중심이라 `board/quality-doc/inventory/report` 구현에는 부족하므로 `V2` 추가를 권고.

### Q40. P0 기준 구체 설계안/Flyway V2 초안 작성 진행 요청
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - P0 DB 설계 문서 신규 작성:
    - `doc/db/p0_schema_design.md`
  - Flyway 코어 도메인 스키마 추가:
    - `migration/flyway/V2__core_domains.sql`
    - 포함: `board_posts`, `board_post_attachments`, `quality_documents`, `quality_document_acks`, `inventory_balances`, `inventory_movements`, `report_jobs` + FK/INDEX/CHECK 제약
  - 이관 매핑 문서 정합화:
    - `migration/mapping/legacy-sp-to-target-mapping.md` (예정 표기 제거, 신규 테이블 반영)
  - Flyway 문서 갱신:
    - `migration/flyway/README.md` (`V2__core_domains.sql` 명시)
  - 검증:
    - `migration-dry-run` 게이트 통과(상태파일/검증리포트 생성)

### Q41. P0 스키마/Flyway V2 반영 결과 커밋/푸시 요청
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - P0 DB 설계 문서, Flyway V2, 이관 매핑/문서 업데이트, Q&A 누적 반영분을 브랜치에 커밋.
  - 원격 `origin/feature/to-be-dev-env-bootstrap`로 푸시해 PR(`#1`)에 반영.

### Q42. 2.1 달성용 우선순위 계획을 Issue/PR 10개 작업으로 분해 요청
- 사용자 프롬프트:
  - "위 계획을 바로 **Issue/PR 단위(10개 작업)로 쪼개서 실행 순서대로 만들어줘"
- Codex 답변(결과):
  - `Issue 1개 = PR 1개` 원칙으로 10개 실행 작업을 순서화해 제시.
  - 각 작업에 목표, 핵심 구현 범위, 완료 기준(DoD), 선행 의존성을 포함해 즉시 착수 가능한 수준으로 분해.

### Q43. Issue/PR 템플릿 생성 진행 확인
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - 2.1 달성용 10개 작업을 복사/사용 가능한 GitHub Issue 본문 템플릿 문서로 생성:
    - `doc/roadmap/issue-pr-templates-2.1.md`
  - 로드맵 README에 템플릿 문서 링크 추가:
    - `doc/roadmap/README.md`
  - Q&A 누적 정책에 따라 본 요청/결과(Q43) 반영.

### Q44. 2.1 Issue/PR 템플릿 문서 반영 커밋/푸시 요청
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - `doc/roadmap/issue-pr-templates-2.1.md` 신규 문서와 관련 문서 갱신분을 브랜치에 커밋.
  - 원격 `origin/feature/to-be-dev-env-bootstrap`로 푸시해 PR(`#1`)에 반영.

### Q45. 2.1 제품/기능 구현 착수 가능 여부 확인 요청
- 사용자 프롬프트:
  - "이제 dev_plan.md의 2.1 제품/기능 구현을 해도될까요?"
- Codex 답변(결과):
  - 착수 가능(Go)으로 판단.
  - 단, 즉시 8도메인 병렬 구현이 아니라 `SCM-201 -> SCM-202 -> SCM-203/204` 순서로 진행할 것을 권고.

### Q46. 2.1 구현 착수 지시
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - `SCM-201` 산출물 구현 착수.
  - 신규 작성:
    - `doc/roadmap/scm-201-p0-scenarios.md` (P0 입력/출력/오류코드 고정)
    - `doc/adr/ADR-003-gateway-runtime-selection.md`
    - `doc/adr/ADR-004-shared-db-domain-schema-strategy.md`
  - 문서 반영:
    - `doc/roadmap/README.md` (SCM-201 산출물 링크)
    - `doc/dev_plan.md` 2.1 기준 문서 참조 추가
    - `doc/roadmap/progress.json` 업데이트(phase-2 75%)
  - 검증:
    - `scripts/roadmap-report.ps1` 실행 성공
  - Q&A 누적 정책에 따라 본 요청/결과(Q45~Q46) 반영.

### Q47. SCM-201 반영 결과 커밋/푸시 요청
- 사용자 프롬프트:
  - "예"
- Codex 답변(결과):
  - `SCM-201` 관련 신규 문서(시나리오/ADR)와 로드맵/계획 업데이트, Q&A 누적 반영분을 브랜치에 커밋.
  - 원격 `origin/feature/to-be-dev-env-bootstrap`로 푸시해 PR(`#1`)에 반영.

## 비고
- 본 문서는 대화 로그를 기반으로 핵심 질의/응답 결과를 압축 정리한 Q&A 보고서임.

### Q48. SCM-202/SCM-205 병행 실행 및 PR 머지 후 SCM-203 진입 요청
- 사용자 프롬프트:
  - "다음을 바로 실행해줘\n\nSCM-202 Issue/브랜치 생성 후 gateway 모듈부터 구현\n동시에 SCM-205 Issue/브랜치 생성 후 DB 표준화 착수\n두 PR merge 후 SCM-203로 진입"
- Codex 답변(결과):
  - GitHub Issue 생성:
    - `#3` `[SCM-202] Add gateway runtime service with route controls`
    - `#2` `[SCM-205] Standardize datasource, flyway, and persistence baseline`
    - `#6` `[SCM-203] Auth/Member MVP + Gateway 토큰 검증 연동`
  - SCM-202 구현 및 PR:
    - 브랜치: `feature/scm-202-gateway-runtime`
    - 커밋: `8bfbdd6`
    - PR: `#4` (머지 완료)
  - SCM-205 구현 및 PR:
    - 브랜치: `feature/scm-205-db-integration-baseline`
    - 커밋: `ba13328`
    - 변경: 서비스 공통 DB 의존성(data-jdbc/flyway/sqlserver/h2), 8개 서비스 datasource/flyway 표준 설정, `.env*` 표준 변수, `shared/persistence/README.md`
    - 검증: `build`, `unit-integration-test`, `smoke-test` 게이트 통과
    - PR: `#5` (머지 완료)
  - 기준 브랜치 동기화:
    - `feature/to-be-dev-env-bootstrap`를 원격 최신으로 fast-forward
  - SCM-203 진입:
    - 워크트리 생성: `C:\Users\CMN-091\projects\SCM_RFT_scm203`
    - 브랜치 생성/푸시: `feature/scm-203-auth-member-mvp`
### Q49. SCM-203 착수/브랜치 정리 전 사전 검토·준비사항 요청
- 사용자 프롬프트:
  - "다음으로 바로 진행하기 위해 사전에 검토 또는 준비사항을 정리해줘\n\nSCM-203에서 Auth 토큰 발급/검증 + Member 조회 API 골격부터 구현 시작\n머지 완료된 feature/scm-202-*, feature/scm-205-* 브랜치 정리(원격/로컬 삭제)"
- Codex 답변(결과):
  - SCM-203 착수 전 체크리스트를 구현/테스트/게이트/리스크 기준으로 순서화해 제시.
  - 브랜치 정리는 worktree 연결 해제 -> 로컬 삭제 -> 원격 삭제 순서로 안전 절차를 제시.
  - 현재 상태 확인:
    - `feature/scm-203-auth-member-mvp` 작업 브랜치 존재
    - `feature/scm-202-gateway-runtime`, `feature/scm-205-db-integration-baseline` 원격 브랜치 존재(정리 대상)
### Q50. SCM-203 사전 준비 체크리스트 점검/보완 실행 요청
- 사용자 프롬프트:
  - "다음의 사전 준비 체크리스트 (바로 실행 순서)에 따라 점검하고 준비가 않된 부분은 해결해줘."
- Codex 답변(결과):
  - 1) 기준선 고정 확인
    - `feature/to-be-dev-env-bootstrap` 원격 동기화 상태 확인(0/0)
    - Open 이슈는 `#6`만 유지 확인
    - 구현 준비 변경은 `feature/scm-203-auth-member-mvp`에서만 반영
  - 2) API 계약 고정
    - `shared/contracts/auth.openapi.yaml`: `login`, `token verify` 엔드포인트 확정
    - `shared/contracts/member.openapi.yaml`: `member by id`, `member search` 확정 및 검색 파라미터/응답 스키마 보강
  - 3) 토큰 정책 확정
    - 신규 ADR: `doc/adr/ADR-005-auth-token-policy-and-gateway-validation.md`
    - 정책: JWT HS256, 30분 만료, 필수 클레임(`sub`,`roles`,`iat`,`exp`), Gateway는 auth introspection(`/api/auth/v1/tokens/verify`) 단일안 채택
  - 4) DB/마이그레이션 선확인 및 보완
    - `V1__baseline.sql`, `V2__core_domains.sql` 확인
    - 신규 추가: `migration/flyway/V3__auth_member_lookup_indexes.sql` (members/auth_sessions 조회 인덱스 + FK)
    - `migration/flyway/README.md`에 V3 반영
  - 5) SCM-203 구현 골격 범위 잠금
    - 신규 문서: `doc/roadmap/scm-203-scope-lock.md`
    - `doc/roadmap/README.md`에 SCM-203 잠금 아티팩트 링크 반영
  - 6) 게이트 고정 및 실행
    - `build`, `unit-integration-test`, `contract-test`, `smoke-test` 실행 통과
  - 7) 머지 완료 브랜치 정리
    - worktree 제거: `SCM_RFT_scm202`, `SCM_RFT_scm205`
    - 로컬 브랜치 삭제: `feature/scm-202-gateway-runtime`, `feature/scm-205-db-integration-baseline`
    - 원격 브랜치 삭제: 동일 2개 브랜치 삭제 완료
    - 현재 원격 유지 브랜치: `feature/scm-203-auth-member-mvp`
  - SCM-203 준비 반영 커밋/푸시:
    - 브랜치: `feature/scm-203-auth-member-mvp`
    - 커밋: `e19a866`