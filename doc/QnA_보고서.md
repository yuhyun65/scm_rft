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

## 비고
- 본 문서는 대화 로그를 기반으로 핵심 질의/응답 결과를 압축 정리한 Q&A 보고서임.
