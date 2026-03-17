# 템플릿 D — 7게이트 안정화 실행 프롬프트

> **사용 시점:** 단독 게이트 실행이 필요할 때 (PR 머지 전 최종 검증, DoD 확인 등)
> **목적:** 게이트 실패 → 진단 → 복구 → 재실행 루프를 프롬프트 내 조건 처리로 대체
> **절감 효과:** 환경 장애 포함 시 4~8회 Q&A → 2~3회

---

## 프롬프트 본문 (복사해서 사용)

```
RunId: {SCM-XXX}-{YYYYMMDD}-R{N} 기준으로 7게이트 무스킵 연속 실행해줘.

【사전 준비 — 게이트 실행 전 순서대로 자동 처리】
1. 서비스 포트(8081 / 8082 / 18080) 점유 프로세스 종료
2. Gradle daemon 정지: .\gradlew.bat --stop  (GRADLE_USER_HOME=~/.gradle-scm-rft)
3. Docker daemon 정상 확인: docker info 2회 연속 성공 대기
4. staging 기동: scripts/staging-up.ps1
5. auth/member/gateway 기동 후 /actuator/health UP 확인
   - auth   : java -jar ... --server.port=8081 --spring.datasource.url={SQL_URL} &
   - member : java -jar ... --server.port=8082 --spring.datasource.url={SQL_URL} &
   - gateway: java -jar ... --server.port=18080 --GATEWAY_POLICY_PATH={정책경로} &
6. 헬스 UP 확인 후 게이트 시작

【고정 환경값】
- SQL URL      : jdbc:sqlserver://localhost:11433;databaseName=MES_HI;encrypt=true;trustServerCertificate=true
- SQL Container: scm-stg-sqlserver
- env 파일     : .env.staging
- Gateway 정책 : infra/gateway/policies/local-auth-member-e2e.yaml
- GRADLE_USER_HOME: ~/.gradle-scm-rft
  (쓰기 불가 시 ~/.gradle-ci-scm-rft 자동 전환)
- SCM_SQL_CONTAINER_NAME=scm-stg-sqlserver
- SCM_ENV_FILE=.env.staging
- SCM_DB_NAME=MES_HI

【증적 경로】
runbooks/evidence/{RunId}/gate-{게이트명}.log

【게이트별 실패 자동 복구 규칙】
- build AccessDeniedException (.gradle lock):
    → Gradle daemon 정지 + GRADLE_USER_HOME 전환 후 1회 재실행
- security-scan rg os error 33:
    → 서비스/Gradle 프로세스 정지 + .gradle-scm-rft 재생성 후 1회 재실행
- smoke-test 504 (Circuit Breaker):
    → auth login pre-warm 1회 호출 + 3초 대기 후 1회 재시도
- smoke-test auth 미기동:
    → auth/member/gateway 재기동 후 헬스 확인 후 재실행
- migration-dry-run MES_HI_LEGACY 미존재:
    → scripts/perf-member-prepare-db.ps1 실행 후 재시도
- 위 복구 시도 후에도 실패:
    → 중단하고 실패 원인, 로그 경로, 권장 복구 절차를 보고해줘.

【완료 기준】
- 7게이트 전체 exit code 0
- runbooks/evidence/{RunId}/ 내 로그 스캔: [FAIL] 0건, [SKIP] 0건
- 완료 후: runbooks/evidence/LATEST-7GATE-RUNID.txt 에 RunId 기록

【완료 시 자동 처리】
- 게이트 증적 요약을 PR 코멘트로 첨부 (PR #{N}이 지정된 경우)
- doc/QnA_보고서.md 해당 항목 업데이트 후 커밋/푸시
```

---

## RunId 명명 규칙

```
형식: {이슈번호}-{YYYYMMDD}-R{N}
예시: SCM-233-7GATE-20260312-R1
      SCM-229-final
      CHK-20260316-{HHMMSS}  (체크 전용 실행 시)
```

---

## 게이트별 예상 소요 시간 및 타임아웃 기준

| 게이트 | 정상 소요 | 타임아웃 기준 | 비고 |
|---|---|---|---|
| build | 2~4분 | 10분 초과 시 daemon 재시작 | cold start 시 최대 8분 |
| unit-integration-test | 3~6분 | 15분 | gateway 테스트 포함 |
| contract-test | 1~2분 | 5분 | 8개 계약 검증 |
| lint-static-analysis | 1~2분 | 5분 | |
| security-scan | 1~3분 | 8분 | rg 스캔 포함 |
| smoke-test | 2~4분 | 10분 | E2E ON 기준 |
| migration-dry-run | 1~2분 | 8분 | DB 접속 필요 |

---

## 환경 사전 점검 단독 프롬프트 (게이트 전 빠른 확인이 필요할 때)

```
게이트 실행 전 환경 사전 점검만 실행해줘.

점검 항목:
1. docker info — daemon UP/DOWN
2. 포트 8081/8082/18080/11433 점유 상태
3. GRADLE_USER_HOME 쓰기 가능 여부
4. .env.staging 파일 존재 확인
5. staging 컨테이너(scm-stg-sqlserver) 실행 상태

정상이면 "게이트 시작 가능" 한 줄로 보고해줘.
이상 항목이 있으면 항목별 복구 커맨드와 함께 보고해줘.
```

---

## 적용 전/후 비교

| 구분 | 기존 방식 (Q&A 횟수) | 최적화 후 |
|---|---|---|
| 게이트 실패 원인 파악 | Q_n+1 (1회) | 자동 진단 후 복구 처리 |
| 복구 실행 승인 | Q_n+2 (1회) | 조건부 자동 처리 |
| 복구 후 재실행 확인 | Q_n+3 (1회) | 자동 재실행 |
| 환경 재확인 | Q_n+4 (1~2회) | 사전 준비 단계로 선행 처리 |
| **환경 정상 시** | **2~3회** | **1회** |
| **환경 장애 포함 시** | **4~8회** | **2~3회** |
