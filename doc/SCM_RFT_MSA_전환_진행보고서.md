# SCM_RFT MSA 전환 진행보고서

- 기준일: 2026-02-26
- 비교 기준 문서:
  - `doc/scm_rft_design.md` (설계서)
  - `doc/QnA_보고서.md` (프롬프트/응답 이력)
- 분석 범위:
  - Q1~Q83 이력
  - PR #16, #17, #18, #21, #22 및 이슈 #19, #20

## 1. 종합 요약
- 결론: 설계서 1~6장은 대부분 구현/반영 완료, 7장은 Phase 5(리허설 반복/컷오버 준비) 중심으로 진행 필요, 8장은 체크리스트 자산은 구축되었고 실측 증적 보강이 필요함.
- 현재 단계: "핵심 도메인 MVP + 게이트/런북/검증 템플릿"까지 완료된 상태이며, Big-Bang 실제 전환 직전 검증 단계로 진입 가능.

## 2. 설계서 대비 진행현황 (비교 분석)

| 설계서 장 | 설계 요구사항(핵심) | QnA/산출물 근거 | 상태 | 판정 |
|---|---|---|---|---|
| 1. 목적 | Big-Bang 전환 방향, 1인+Codex+Agentic 체계 확립 | Q1~Q3, Q14, Q23 | 완료 | 방향성과 실행체계가 문서/운영규칙으로 고정됨 |
| 2. AS-IS 분석 | 레거시 구조/보안/운영 리스크 식별 | Q4~Q6 | 완료 | 전환 리스크(인증, Order-Lot, 첨부, 출력)가 명시됨 |
| 3. TO-BE 개발환경 | Java21/Gradle/Compose/로컬표준/구조표준 | Q19~Q21, Q32~Q34 | 완료 | 개발환경 재현성과 표준 버전 고정이 반영됨 |
| 4. Codex+Agentic 체계 | 역할분리/에이전트 루프/산출물 운영 | Q23~Q24, Q69~Q71 | 완료 | 실행 Runbook, 체크리스트, 템플릿으로 운영 가능 |
| 5. GitHub 운영표준 | 이슈-브랜치-PR 원칙, 게이트 운영 | Q25~Q26, Q42~Q44, Q70 | 완료 | `1 Issue = 1 PR = 1 Branch` 규칙이 실제로 적용됨 |
| 6. Big-Bang 대응요건 | 리허설/컷오버/롤백/관측/검증 자동화 | Q27~Q31, Q74~Q77, Q83 | 대부분 완료 | 정책/런북/검증 SQL/Signoff 문서는 완료, 실측 반복 실행은 추가 필요 |
| 7. 권장 추진순서 | Phase 1~5 순차 이행 | Q29~Q31, Q45~Q47, Q48~Q68, Q82~Q83 | 진행중 | Phase 1~4는 상당 부분 완료, Phase 5(반복 리허설/Go-NoGo 고도화) 남음 |
| 8. 즉시 실행 체크리스트 | 버전고정, CI, 계약, Flyway, 리허설 기준 | Q31~Q34, Q71~Q77, Q83 | 진행중 | 체크리스트 자산은 완료, 일부 게이트/실측 증적 밀도 보강 필요 |

## 3. 구현/운영 성과 요약

### 3.1 코드/기능 구현 성과
- SCM-210/211/212 구현 및 머지 완료
  - PR #16 (Order-Lot P0 API MVP)
  - PR #17 (Board + Quality-Doc MVP)
  - PR #18 (Gateway 정책 런타임 반영)
- SCM-213/214 구현 및 머지 완료
  - PR #21 (R1 검증 SQL 팩 + 실행 스크립트)
  - PR #22 (리허설/Signoff Runbook + 게이트 규칙 강화)
- 이슈 상태
  - #19 CLOSED (SCM-213)
  - #20 CLOSED (SCM-214)

### 3.2 산출물 체계 성과
- 계약(OpenAPI): `shared/contracts/*`
- 이관 검증: `migration/sql/r1-validation/*`, `migration/reports/R1-report-template.md`
- 운영/리허설: `runbooks/*`, `scripts/scm214-rehearsal-r1.ps1`
- 실행 이력: `doc/QnA_보고서.md`

### 3.3 머지/검증 운영 성과
- PR checks가 비어있는 상황을 보완하기 위해 로컬 5게이트 증적 코멘트 운영 적용
- 순차 머지 시 머지 직전 rebase 규칙 실제 적용(#17/#18/#22)

## 4. 잔여 갭 및 리스크

| 항목 | 현재 상태 | 영향 | 보완 작업 |
|---|---|---|---|
| GitHub PR checks 공백 | `gh pr checks` 결과가 비어있는 케이스 존재 | 원격 CI 가시성 저하 | 로컬 증적 코멘트 유지 + Actions 체크 연동 점검 |
| Gateway E2E smoke | 일부 게이트에서 e2e smoke가 SKIP로 기록됨 | 컷오버 전 실제 체인 신뢰도 저하 | `SCM_ENABLE_GATEWAY_E2E_SMOKE=1` 고정 실행 규칙 적용 |
| SCM-213 실측 데이터 | SQL 템플릿/실행기반은 완료, 실제 대량 실측 결과 누적은 추가 필요 | Go/No-Go 근거 약화 | `sqlcmd` 기반 실측 결과를 `migration/reports/`에 RunId 단위 적재 |
| 리허설 반복 횟수 | R1 체계/문서는 완료, 반복 리허설(3회+) 근거 부족 | Big-Bang 전환 리스크 상존 | R1/R2/R3 반복 리허설 및 비교 리포트 누적 |
| 기준 브랜치 로컬 동기화 | 로컬 워킹트리에 미커밋 변경 누적 | 머지 후 동기화/회귀 검증 혼선 | 산출물 PR 분리/정리 후 base 브랜치 clean 동기화 |

## 5. 다음 실행 권고 (실행 순서)

1. `SCM_ENABLE_GATEWAY_E2E_SMOKE=1`로 5게이트 재실행 후 증적 고정
2. SCM-213 실측 실행
   - `migration/scripts/run-r1-validation.ps1`로 RunId 결과 생성
   - 결과를 `migration/reports/`에 도메인별 첨부
3. SCM-214 리허설 R1 실측 수행
   - `scripts/scm214-rehearsal-r1.ps1` 실행
   - `runbooks/go-nogo-signoff.md`에 근거 링크/수치 채움
4. 리허설 2회 추가(R2/R3) 후 Go/No-Go 임계치 안정성 검증
5. 컷오버 초안 확정 및 최종 승인 절차 진입

## 6. 최종 판정
- 판정: **MSA 전환 준비 단계는 완료에 근접(구현/운영체계 구축 완료), 실제 Big-Bang 컷오버 전 필수 실측/리허설 증적 보강 단계**.
- 실제 전환 착수 조건:
  - 5게이트 연속 PASS(연속 3회)
  - R1~R3 리허설 결과 임계치 충족
  - 데이터 정합성 기준(count/sum/sample/status) 위반 0건
