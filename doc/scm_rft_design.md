# SCM_RFT Big-Bang 리팩토링 설계서

- 문서명: `scm_rft_design`
- 버전: v1.2
- 작성일: 2026-02-24
- 기준: AS-IS 시스템 분석 보고서 + 개발환경 분석/개선안

## 1. 목적
- 레거시 SCM(`xrw` + 단일 Servlet + 대형 SP) 구조를 Big-Bang 방식으로 MSA 전환한다.
- 전환 실패 확률을 낮추기 위해 개발환경 표준화, 품질 자동화, 보안 기본값 강화를 선행한다.
- `개발자 1인 + Codex + Agentic AI` 체계에서 의사결정/구현/검증을 분리해 생산성을 극대화한다.

## 2. 기존 개발환경(AS-IS) 분석

### 2.1 기술 스택 및 실행 구조
- 서버: JSP/Servlet + 단일 컨트롤러 패턴(`Common.Controller`)
- 화면: XRW(ComSquare/TrustForm 계열), ActiveX 의존
- 데이터: SQL Server + Stored Procedure 중심 처리
- 클라이언트: Windows/IE 계열 + 로컬 파일시스템 + 로컬 MDB 의존

### 2.2 개발/배포 방식
- 빌드 표준 부재(`pom.xml`, `build.gradle` 없음)
- 의존성 수동 관리(`WEB-INF/jar` 직접 관리)
- 소스/바이너리(.java + .class) 동시 버전관리
- 테스트 코드/CI 파이프라인 부재

### 2.3 품질/보안 관점 진단
- DB 접속정보 하드코딩 및 비밀관리 체계 부재
- 입력값 기반 동적 SQL 조립 경로 존재
- 인증정보 노출 가능 경로(URL query 등) 존재
- 구형 해시(MD5 계열) 및 일부 평문 처리 흔적
- ActiveX/로컬 실행 기반으로 운영 표준화와 보안 통제가 어려움

### 2.4 개발 생산성 리스크
- 환경 재현성이 낮아 이슈 재현/해결 리드타임이 길다.
- 장애 원인 추적에 필요한 로그/트레이스 표준이 없다.
- Big-Bang 전환에 필요한 이관 검증 자동화 기반이 없다.

## 3. 신규 시스템 최적 개발환경(TO-BE) 제안

### 3.1 공통 런타임 표준
- OS: Windows 11 + WSL2
- 컨테이너: Docker Desktop + Docker Compose
- Backend: Java 21 LTS + Spring Boot 3.x + Gradle 8.x
- Frontend: Node.js 22 LTS + React + TypeScript + Vite
- Data/Integration: SQL Server(초기), Redis, Message Broker(RabbitMQ 또는 Kafka)

### 3.2 로컬 개발 표준
- 서비스별 `dev` 프로파일 제공(단독 실행/통합 실행 모두 지원)
- 로컬 공통 스택: `sqlserver`, `redis`, `broker`, `loki`, `prometheus`, `grafana`, `tempo`
- 개발자 환경 부트스트랩 스크립트(`make dev-up` 또는 `./scripts/dev-up.ps1`) 제공

### 3.3 저장소 구조 표준
```text
SCM_RFT/
  services/
    auth/
    member/
    board/
    quality-doc/
    order-lot/
    inventory/
    file/
    report/
  shared/
  infra/
  migration/
  runbooks/
  doc/
```

### 3.4 빌드/테스트/품질 표준
- 테스트 피라미드: JUnit5(단위) + Testcontainers(통합) + E2E(smoke)
- 계약 테스트: OpenAPI 기반 contract test
- 정적분석: lint + formatting + static analysis
- 보안검증: SAST + secret scan + dependency scan
- DB 변경관리: Flyway(버전 마이그레이션 강제)

### 3.5 운영 준비 포함 개발환경 표준
- 로컬/CI에서 동일한 검증 절차를 강제해 "로컬 통과 = CI 통과"에 가깝게 설계
- Feature Flag로 배포 단위 제어(빅뱅 이후 안정화 대응)
- 표준 로그 포맷(JSON + traceId + userId + domain key) 적용
- 장애 시 분석 단축을 위해 분산트레이싱을 기본 활성화

## 4. Codex + Agentic AI 적용 추진 체계

### 4.1 역할 분리
- 개발자: 요구사항 우선순위, 아키텍처 결정, 최종 승인
- Codex: 코드 구현, 테스트/문서 초안, 리팩토링 및 PR 정리
- Agentic AI: 반복 검증(테스트/보안/이관/릴리즈 체크리스트) 자동화

### 4.2 에이전트 루프
1. Architect Agent: 서비스 경계/계약/API 정의
2. Build Agent: 서비스/이관 코드 구현
3. Test Agent: 계약/통합/회귀 테스트 강화
4. Security Agent: 비밀정보/취약점/인증 흐름 점검
5. Migration Agent: 이관 시나리오/정합성 검증 자동화
6. Release Agent: 컷오버 런북/릴리즈노트 생성

### 4.3 필수 산출물
- OpenAPI 명세 및 예시 payload
- 서비스별 ADR(Architecture Decision Record)
- 이관 리허설 결과 리포트(건수/합계/샘플 비교)
- 컷오버 체크리스트/롤백 플레이북

## 5. GitHub 운영 표준

### 5.1 브랜치/PR
- 기본 브랜치: `main`
- 작업 브랜치: `feature/*`, `fix/*`, `chore/*`
- PR 템플릿 필수 항목: 변경 범위, 리스크, 테스트 증거, 롤백 영향

### 5.2 CI 필수 게이트
1. build
2. unit/integration test
3. contract test
4. lint/static analysis
5. SAST + secret scan + dependency scan
6. migration dry-run
7. smoke test

## 6. Big-Bang 전환 대응 환경 요구사항

### 6.1 리허설 환경
- 운영 유사 스펙의 staging 별도 구성
- 이관 스크립트 재실행/복구 가능한 구조
- 정합성 자동검증(건수/합계/샘플/첨부파일 존재성)

### 6.2 컷오버 운영 환경
- 실시간 대시보드(로그/메트릭/트레이스)
- API Gateway 수준의 트래픽/장애 격리 정책
- 즉시 롤백 가능한 DB 스냅샷/백업 체계

## 7. 권장 추진 순서
1. 저장소 골격/템플릿/CI 게이트 구축
2. Auth/Member + Gateway 우선 구현
3. OrderLot + File 핵심 도메인 구현
4. Board/QualityDoc/Inventory/Report 구현 및 통합
5. 이관 리허설 3회 이상 후 Big-Bang 컷오버

## 8. 즉시 실행 체크리스트
1. 개발 표준 버전 고정(Java/Node/Gradle/Docker)
2. 로컬 Compose + dev bootstrap 스크립트 완성
3. OpenAPI 계약서와 Flyway baseline 작성
4. CI 파이프라인(빌드/테스트/보안/이관 dry-run) 활성화
5. 컷오버 리허설 일정과 Go/No-Go 기준 확정
