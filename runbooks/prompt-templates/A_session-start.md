# 템플릿 A — 세션 시작 컨텍스트 고정 프롬프트

> **사용 시점:** 매 작업 세션의 첫 번째 프롬프트
> **목적:** 저장소 경로·브랜치·환경값을 선언하여 세션 전체의 컨텍스트 혼선 및 환경 재확인 Q&A를 제거
> **절감 효과:** 세션당 환경 확인 Q&A 2~3회 → 0회

---

## 프롬프트 본문 (복사해서 사용)

```
【세션 고정 컨텍스트 — 세션 전체에서 이 값을 유지해줘】

■ 저장소 경로  : C:\Users\CMN-091\projects\SCM_RFT
■ 기준 브랜치  : feature/to-be-dev-env-bootstrap
■ 작업 원칙    : 1 Issue = 1 PR = 1 전용 브랜치
■ QnA 기록    : doc/QnA_보고서.md (모든 작업 완료 시 즉시 업데이트 포함)

■ 고정 환경값
  - SQL 접속    : jdbc:sqlserver://localhost:11433;databaseName=MES_HI;encrypt=true;trustServerCertificate=true
  - SQL Container: scm-stg-sqlserver
  - env 파일    : .env.staging
  - Gateway 정책: infra/gateway/policies/local-auth-member-e2e.yaml
  - GRADLE_USER_HOME: ~/.gradle-scm-rft (쓰기 불가 시 ~/.gradle-ci-scm-rft 로 자동 전환)

■ 필수 게이트 (7개 무스킵)
  build / unit-integration-test / contract-test /
  lint-static-analysis / security-scan / smoke-test / migration-dry-run

■ 증적 경로 규칙: runbooks/evidence/{RunId}/gate-{이름}.log

【전 세션 종료 상태】          ← 아래 값을 실제로 채운 뒤 사용
  - 마지막 머지 PR : #{N}  (SCM-{XXX} {작업 내용})
  - 현재 진행 브랜치: feature/scm-{XXX}-{name}  (없으면 기준 브랜치)
  - 다음 착수 대상  : SCM-{XXX} — {한 줄 설명}
  - 미처리 항목     : {없음 / 있으면 내용 기재}

위 컨텍스트를 고정하고, 이어서 다음 작업을 진행해줘.
```

---

## 작성 가이드

| 치환 항목 | 찾는 위치 | 예시 |
|---|---|---|
| `#{N}` | 전 세션 종료 메시지 또는 GitHub PR 목록 | `#58` |
| `SCM-{XXX}` | doc/QnA_보고서.md 마지막 항목 | `SCM-239` |
| `feature/scm-{XXX}-{name}` | `git branch` 결과 | `feature/scm-240-ci-gates` |
| 다음 착수 대상 | releas_plan_procces.md 또는 전 세션 종료 정리 | `SCM-241 — 증적 영속성` |

---

## 적용 전/후 비교

| 구분 | 기존 방식 | 최적화 후 |
|---|---|---|
| 저장소 경로 확인 | Q&A 1회 소비 (Q32, Q129 사례) | 선언으로 대체 → 0회 |
| 브랜치 상태 확인 | Q&A 1회 소비 | 선언으로 대체 → 0회 |
| 환경값 재지정 | 게이트 실패 후 Q&A 1~2회 | 사전 고정 → 복구 루프 대폭 감소 |
| **소계** | **2~4회** | **0회** |
