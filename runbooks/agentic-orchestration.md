# SCM_RFT Agentic Coding Orchestration 체계

> **문서 목적:** 1인 개발자 + Codex AI 체계에서 SCM_RFT 프로젝트의 agentic coding을 체계적으로 운영하기 위한 오케스트레이션 설계 기준
>
> **연계 문서:**
> - `doc/dev_plan.md` — Phase별 실행 계획, DoD 정의, 에이전트 실행 표준(4.2절)
> - `runbooks/fixed-project-context.md` — 고정 환경값 및 출력 원칙
> - `runbooks/prompt-templates/` — 세션별 프롬프트 템플릿 A~E

---

## 1. 오케스트레이션 개요

### 1.1 운영 모델

```
개발자 (Human)
    │
    │  Issue 정의 / DoD 선언 / 예외 승인
    │
    ▼
Codex AI (Orchestrator)
    │
    ├── Architect Agent  → OpenAPI 계약 / ADR 작성
    ├── Build Agent      → 코드 / 테스트 구현
    ├── Test Agent       → 5~7 게이트 실행 / 증적 생성
    ├── Security Agent   → SAST / secret scan / 의존성 점검
    ├── Migration Agent  → Flyway dry-run / 데이터 검증 리포트
    └── Release Agent    → Release note / runbook 갱신
```

**핵심 원칙:**
- 에이전트는 역할별로 순차 실행하되, 독립 이슈는 병렬 실행 가능
- 각 단계의 완료는 **수치 기반 DoD**로 판정 — 모호한 완료 없음
- 개발자는 **예외 발생 시에만** 개입 (2회 자동 복구 후 보고 → 인간 판단)
- 모든 산출물은 지정된 경로에 즉시 커밋 (WIP 상태 미허용)

### 1.2 Issue 단위 원칙

```
GitHub Issue 1개 = Agentic Run 1개 = 전용 브랜치 1개 = PR 1개
```

| 항목 | 규칙 |
|---|---|
| 이슈 크기 | 1~2일 이내 완료 가능한 크기 |
| 브랜치 명 | `feature/scm-{XXX}-{kebab-설명}` |
| 기준 브랜치 | `feature/to-be-dev-env-bootstrap` |
| 머지 방식 | squash merge (커밋 히스토리 단순화) |
| 브랜치 정리 | 머지 직후 로컬 + 원격 삭제 |

---

## 2. 에이전트 역할 정의

### 2.1 Architect Agent

**책임:** 구현 전 설계 산출물 확정

| 항목 | 내용 |
|---|---|
| 입력 | GitHub Issue 내용, `doc/scm_rft_design.md`, AS-IS SP 목록 |
| 출력 | `shared/contracts/{domain}.openapi.yaml`, `doc/adr/ADR-{N}-{설명}.md` |
| DoD | OpenAPI 파일 존재 + contract-test PASS + ADR 내 의사결정 근거 명시 |
| 트리거 | 신규 API 도메인 착수 시, 또는 기존 계약 변경 이슈 |
| 제외 | 기존 계약 범위 내 로직 구현 → Build Agent 직접 착수 |

**Codex 실행 명령 패턴:**
```
SCM-{XXX} 의 OpenAPI 계약 초안을 작성해줘.
- AS-IS SP: {SP명 목록}
- 출력: shared/contracts/{도메인}.openapi.yaml
- 기준: doc/scm_rft_design.md {관련 장}
- DoD: contract-test gate PASS, ADR-{N} 작성 완료
```

---

### 2.2 Build Agent

**책임:** 코드 및 테스트 구현

| 항목 | 내용 |
|---|---|
| 입력 | OpenAPI 계약(`shared/contracts/`), ADR, GitHub Issue DoD |
| 출력 | `services/{서비스명}/src/main/**`, `services/{서비스명}/src/test/**` |
| DoD | build gate PASS + unit-integration-test PASS + [FAIL] 0건 |
| 트리거 | Architect Agent 완료(contract-test PASS) 이후 |
| 자동 처리 | add/commit/push 중간 확인 없이 자동 실행 |

**구현 우선순위 규칙:**
1. Controller/DTO (OpenAPI → 스텁 생성)
2. Service 비즈니스 로직
3. Repository/Entity (JPA)
4. 통합 테스트 (Testcontainers 활용)
5. 계약 테스트 연결

---

### 2.3 Test Agent

**책임:** 품질 게이트 실행 및 증적 생성

| 항목 | 내용 |
|---|---|
| 입력 | 구현된 코드, RunId, 환경값 |
| 출력 | `runbooks/evidence/{RunId}/gate-{게이트명}.log`, `LATEST-7GATE-RUNID.txt` |
| DoD | 7게이트 전체 exit code 0, [FAIL] 0건, [SKIP] 0건 |
| 트리거 | Build Agent 완료(build/unit-integration-test PASS) 이후 |
| 자동 복구 | 게이트 실패 시 유형별 1회 자동 복구 후 재시도 (→ D 템플릿 참조) |

**RunId 명명:**
```
{이슈번호}-{YYYYMMDD}-R{N}
예: SCM-210-20260317-R1
```

**5게이트 (이슈 구현 시 필수):**
```
build → unit-integration-test → contract-test → smoke-test → migration-dry-run
```

**7게이트 (PR 머지 전 최종 검증 시):**
```
build → unit-integration-test → contract-test → lint-static-analysis
    → security-scan → smoke-test → migration-dry-run
```

---

### 2.4 Security Agent

**책임:** 보안 취약점 사전 차단

| 항목 | 내용 |
|---|---|
| 입력 | 구현 코드, `runbooks/security-checklist.md` |
| 출력 | 보안 스캔 결과 → `runbooks/evidence/{RunId}/gate-security-scan.log` |
| DoD | High 이상 이슈 0건, 비밀정보 노출 패턴 0건 |
| 트리거 | PR 머지 전 7게이트 실행 시 (lint-static-analysis 직후) |
| 자동 복구 | `rg os error 33` → 서비스/Gradle 프로세스 정지 후 1회 재실행 |

**점검 항목:**
- 소스코드 내 secret 하드코딩 (`rg` 스캔)
- OWASP 의존성 취약점 (SAST)
- `.env` 파일 미커밋 확인
- JWT secret 노출 여부

---

### 2.5 Migration Agent

**책임:** 데이터 이관 안전성 사전 검증

| 항목 | 내용 |
|---|---|
| 입력 | Flyway 스크립트, `migration/mapping/legacy-sp-to-target-mapping.md` |
| 출력 | `migration/reports/validation-{날짜}-{설명}.md`, dry-run 실행 로그 |
| DoD | migration-dry-run exit code 0, Critical mismatch 0건 |
| 트리거 | DB 스키마 변경 이슈 시 (Flyway V{N}__.sql 변경 포함 시) |
| 사전 조건 | `scripts/perf-member-prepare-db.ps1` 실행 완료 (MES_HI_LEGACY 존재) |

**Flyway 버전 관리 규칙:**
```
버전 번호는 반드시 단조 증가 (V{N} → V{N+1})
병렬 이슈 착수 시 버전 번호 사전 예약 필수 (충돌 방지)
```

---

### 2.6 Release Agent

**책임:** 릴리즈 산출물 갱신 및 세션 종료 처리

| 항목 | 내용 |
|---|---|
| 입력 | 완료된 PR 목록, 증적 로그, `doc/QnA_보고서.md` |
| 출력 | `runbooks/release-note.md` 갱신, `doc/QnA_보고서.md` 업데이트 |
| DoD | PR 머지 확인 + Issue close + `doc/roadmap/progress.json` 갱신 |
| 트리거 | squash 머지 완료 이후 자동 실행 |
| 자동 처리 | doc/QnA_보고서.md 커밋/푸시, progress.json 갱신, 브랜치 삭제 |

---

## 3. 오케스트레이션 흐름

### 3.1 단일 이슈 전체 흐름 (Standard Flow)

```
┌─────────────────────────────────────────────────────────────┐
│                     개발자 입력                              │
│  GitHub Issue 작성 (DoD 수치 포함)                           │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│           [세션 시작] 템플릿 A 실행                          │
│  저장소 경로 / 브랜치 / 환경값 / 전 세션 상태 고정           │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│          도메인 신규? (계약 미존재 여부 확인)                │
└──────────┬──────────────────────┬───────────────────────────┘
           │ YES                  │ NO
           ▼                      ▼
   ┌───────────────┐      ┌───────────────────┐
   │ Architect     │      │ 기존 계약 확인     │
   │ OpenAPI + ADR │      │ shared/contracts/ │
   └───────┬───────┘      └────────┬──────────┘
           │ contract-test PASS    │
           └──────────┬────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────┐
│           Build Agent  [템플릿 B 원샷 실행]                  │
│  브랜치 생성 → 코드 구현 → 테스트 → add/commit/push          │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│           Test Agent  (5게이트)                              │
│  build → unit-integration-test → contract-test               │
│       → smoke-test → migration-dry-run                       │
│                                                              │
│  실패 시: 유형별 자동 복구 1회 → 재시도                       │
│  2회 실패: 중단 + 원인 보고 → 개발자 판단                    │
└─────────────────────┬───────────────────────────────────────┘
                      │ 5게이트 전체 PASS
                      ▼
┌─────────────────────────────────────────────────────────────┐
│           Security Agent  (7게이트 추가 실행)                │
│  lint-static-analysis → security-scan                        │
└─────────────────────┬───────────────────────────────────────┘
                      │ High 이슈 0건
                      ▼
┌─────────────────────────────────────────────────────────────┐
│           PR 생성 + 증적 코멘트 첨부                         │
│  gh pr create → 로컬 증적 코멘트 → squash 머지               │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│           Release Agent  자동 처리                           │
│  Issue close → 기준 브랜치 fast-forward                       │
│  → QnA_보고서.md 업데이트 → progress.json 갱신               │
│  → 브랜치 삭제 (로컬 + 원격)                                 │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│           [세션 종료] 템플릿 E 실행                          │
│  미커밋 확인 → 서비스 종료 → Docker down → 워크트리 정리     │
│  → 다음 세션 시작점 자동 요약 출력                           │
└─────────────────────────────────────────────────────────────┘
```

---

### 3.2 병렬 이슈 흐름 (Parallel Flow)

독립 이슈 2~3개를 동시 처리할 때 [템플릿 C] 사용:

```
기준 브랜치 동기화
        │
        ├─────────────────┬──────────────────┐
        ▼                 ▼                  ▼
  워크트리 A           워크트리 B          워크트리 C
  SCM-{A}              SCM-{B}             SCM-{C}
  Build→Test→PR        Build→Test→PR       (선행 의존 시
                                            A+B 머지 후 착수)
        │                 │
        └────────┬─────────┘
                 ▼
        완료 순서대로 PR → 머지 → 정리
                 │
                 ▼
        후속 이슈 자동 착수 준비
```

**병렬 가능 조건:**
- 서로 다른 `services/` 디렉터리 수정
- `shared/contracts/` 또는 `build.gradle` 공유 없음
- Flyway 버전 번호 중복 없음
- DB 스키마 교집합 없음

---

### 3.3 Phase별 오케스트레이션 전략

| Phase | 실행 전략 | 주 에이전트 | 병렬 가능 여부 |
|---|---|---|---|
| Phase 2: Auth/Member + Gateway | Architect → Build → Test 순차 | Architect + Build | 불가 (상호 의존) |
| Phase 3: OrderLot + File | 병렬 실행 후 통합 | Build + Migration | 가능 (독립 도메인) |
| Phase 4: 나머지 4도메인 | 2개씩 병렬 묶음 | Build + Test | 가능 (템플릿 C 활용) |
| Phase 5: 리허설 | 게이트 단독 반복 | Test + Migration | 직렬 (순서 의존) |

---

## 4. 트리거 및 핸드오프 규칙

### 4.1 에이전트 간 핸드오프 조건

| FROM → TO | 핸드오프 조건 | 실패 시 처리 |
|---|---|---|
| 개발자 → Architect | Issue DoD 명시 완료 | DoD 불명확 시 개발자에게 재질문 |
| Architect → Build | contract-test PASS | 계약 수정 후 재시도 |
| Build → Test | build + unit-integration-test PASS | 코드 수정 후 재빌드 |
| Test → Security | 5게이트 전체 PASS | 실패 유형별 자동 복구 (D 템플릿) |
| Security → PR | High 이슈 0건 | 취약점 수정 후 재스캔 |
| PR → Release | squash 머지 완료 | 머지 충돌 시 개발자 확인 요청 |

### 4.2 개발자 개입 트리거 (Escalation Rules)

Codex가 **자동 처리하지 않고 개발자에게 보고하는 조건:**

| 조건 | 보고 내용 |
|---|---|
| 게이트 자동 복구 2회 실패 | 실패 원인 + 로그 경로 + 권장 복구 절차 |
| 구현 범위 외 변경 발생 | 발생 파일 + 변경 내용 + 범위 포함 여부 확인 요청 |
| 머지 충돌 (conflict) | 충돌 파일 목록 + 충돌 내용 |
| Flyway 버전 번호 충돌 | 충돌 버전 + 예약 버전 목록 |
| `shared/contracts/` 하위 계약 변경 | 영향받는 다운스트림 서비스 목록 |
| PR 리뷰 코멘트 (CI 외) | 코멘트 내용 요약 + 권장 대응 |

---

## 5. 상태 관리 (State Management)

### 5.1 프로젝트 상태 파일

| 파일 | 역할 | 갱신 주체 | 갱신 시점 |
|---|---|---|---|
| `doc/roadmap/progress.json` | 이슈/Phase 완료 여부 추적 | Release Agent | PR 머지 완료 직후 |
| `doc/QnA_보고서.md` | Q&A 실행 이력 전체 | Release Agent | 각 이슈 완료 후 |
| `runbooks/evidence/LATEST-7GATE-RUNID.txt` | 마지막 7게이트 RunId | Test Agent | 7게이트 완료 직후 |
| `runbooks/fixed-project-context.md` | 고정 환경값 기준 | 개발자 수동 | 환경 변경 시만 |

### 5.2 세션 간 컨텍스트 연속성

```
세션 종료 (템플릿 E)
    │  → 【다음 세션 시작점】 자동 출력
    │     - 마지막 머지 PR 번호
    │     - 현재 브랜치 상태
    │     - 최신 커밋 해시
    │     - 다음 착수 이슈
    │     - 환경 상태 (Docker DOWN/UP)
    │
    ▼ 복사&붙여넣기
세션 시작 (템플릿 A)
    │  → 전 세션 종료 상태 선언
    │  → 저장소 경로 / 브랜치 / 환경값 고정
    │
    ▼
작업 시작 (Q&A 0회 — 환경 재확인 불필요)
```

### 5.3 증적 경로 구조

```
runbooks/evidence/
├── {RunId}/
│   ├── gate-build.log
│   ├── gate-unit-integration-test.log
│   ├── gate-contract-test.log
│   ├── gate-lint-static-analysis.log
│   ├── gate-security-scan.log
│   ├── gate-smoke-test.log
│   └── gate-migration-dry-run.log
└── LATEST-7GATE-RUNID.txt

migration/reports/
└── validation-{날짜}-{이슈번호}.md
```

---

## 6. 프롬프트 템플릿 통합 맵

각 오케스트레이션 단계에서 어떤 템플릿을 사용하는지:

| 오케스트레이션 단계 | 사용 템플릿 | 파일 |
|---|---|---|
| 세션 시작 (컨텍스트 고정) | 템플릿 A | `prompt-templates/A_session-start.md` |
| 단일 이슈 착수~머지 | 템플릿 B | `prompt-templates/B_issue-oneshot.md` |
| 병렬 이슈 2~3개 동시 처리 | 템플릿 C | `prompt-templates/C_parallel-issues.md` |
| 7게이트 단독 실행 / 재검증 | 템플릿 D | `prompt-templates/D_gate-execution.md` |
| 세션 종료 + 다음 세션 준비 | 템플릿 E | `prompt-templates/E_session-close.md` |

**템플릿 선택 판단 트리:**
```
세션 첫 번째 프롬프트? ──────────────────────── YES → 템플릿 A (필수)
        │ NO
        ▼
작업 유형 판단
├── 단일 이슈 착수 ──────────────────────────────────→ 템플릿 B
├── 독립 이슈 2개 이상 동시 진행 ───────────────────→ 템플릿 C
├── 기존 이슈 게이트 재실행 또는 PR 전 최종 검증 ───→ 템플릿 D
└── 오늘 작업 마무리 ────────────────────────────────→ 템플릿 E (필수)
```

---

## 7. 실패 복구 체계 (Failure Handling)

### 7.1 게이트별 자동 복구 규칙

| 실패 유형 | 자동 복구 조치 | 최대 재시도 |
|---|---|---|
| `build` AccessDeniedException (.gradle lock) | Gradle daemon 정지 + GRADLE_USER_HOME 전환 | 1회 |
| `security-scan` rg os error 33 | 서비스/Gradle 정지 + .gradle-scm-rft 재생성 | 1회 |
| `smoke-test` 504 Circuit Breaker | auth login pre-warm 1회 + 3초 대기 | 1회 |
| `smoke-test` auth 미기동 | auth/member/gateway 재기동 + 헬스 확인 | 1회 |
| `migration-dry-run` MES_HI_LEGACY 미존재 | `scripts/perf-member-prepare-db.ps1` 실행 | 1회 |

### 7.2 GRADLE_USER_HOME Fallback

```
GRADLE_USER_HOME=~/.gradle-scm-rft  (기본)
        │ 쓰기 불가 시 자동 전환
        ▼
GRADLE_USER_HOME=~/.gradle-ci-scm-rft  (fallback)
```

### 7.3 에스컬레이션 임계값

```
자동 복구 시도: 최대 2회
        │ 2회 실패 시
        ▼
중단 + 보고
├── 실패 원인 (로그 분석 결과)
├── 로그 파일 경로
├── 권장 수동 복구 절차
└── 재개 방법 안내
```

---

## 8. 환경 고정값 참조

| 항목 | 값 |
|---|---|
| 저장소 경로 | `C:\Users\CMN-091\projects\SCM_RFT` |
| 기준 브랜치 | `feature/to-be-dev-env-bootstrap` |
| SQL URL | `jdbc:sqlserver://localhost:11433;databaseName=MES_HI;encrypt=true;trustServerCertificate=true` |
| SQL Container | `scm-stg-sqlserver` |
| env 파일 | `.env.staging` |
| Gateway 정책 | `infra/gateway/policies/local-auth-member-e2e.yaml` |
| GRADLE_USER_HOME | `~/.gradle-scm-rft` (fallback: `~/.gradle-ci-scm-rft`) |
| auth 포트 | `8081` |
| member 포트 | `8082` |
| gateway 포트 | `18080` |
| SQL 포트 | `11433` |
| Redis 포트 | `16379` |
| Prometheus 포트 | `19090` |

---

## 9. 하루 세션의 오케스트레이션 흐름 요약

```
─────────────────────────────────────────
 08:30  세션 시작
        └→ [템플릿 A] 컨텍스트 고정
           전 세션 종료 상태 + 환경값 선언
─────────────────────────────────────────
 08:31  작업 계획 (개발자)
        └→ 오늘 착수 이슈 결정
           단일 vs 병렬 판단
─────────────────────────────────────────
 08:32  Agentic Run 시작
        └→ [템플릿 B 또는 C]
           Architect → Build → Test → Security
           → PR → Release 자동 처리
─────────────────────────────────────────
  :     이슈 완료 → 다음 이슈 착수
        (기준 브랜치 동기화 자동 처리)
─────────────────────────────────────────
 17:30  세션 종료
        └→ [템플릿 E]
           미커밋 확인 → 서비스/Docker 정리
           → 다음 세션 시작점 요약 자동 출력
─────────────────────────────────────────
 17:31  개발자
        └→ 출력된 요약 복사
           → 내일 템플릿 A에 붙여넣기
─────────────────────────────────────────
```

---

## 10. 오케스트레이션 도입 효과 (예상)

| 지표 | 기존 방식 | 오케스트레이션 적용 후 | 개선율 |
|---|---|---|---|
| 이슈 1건 착수~머지 Q&A | 4~6회 | 1~2회 | ~65% |
| 게이트 실패 복구 루프 | 4~8회 | 2~3회 (자동 복구) | ~55% |
| 세션 시작 환경 확인 | 2~4회 | 0회 (컨텍스트 고정) | ~100% |
| 세션 종료 처리 | 3회 | 1회 (자동 처리) | ~67% |
| 병렬 이슈 처리 시간 | 직렬 대비 100% | 직렬 대비 50~70% | 30~50% |
| **1일 전체 Q&A** | **20~40회** | **8~15회** | **~55%** |

---

*최초 작성: 2026-03-17 | 연계: prompt-templates/README.md, dev_plan.md(4.2절)*
