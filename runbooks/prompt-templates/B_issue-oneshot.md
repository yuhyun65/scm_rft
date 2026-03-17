# 템플릿 B — 이슈 원샷(One-Shot) 실행 프롬프트

> **사용 시점:** 단일 이슈 착수 시
> **목적:** "준비 확인 → 진행 승인 → 커밋/푸시 승인" 3단계를 1개 프롬프트로 통합
> **절감 효과:** 이슈 1건당 평균 4~6회 Q&A → 1~2회

---

## 프롬프트 본문 (복사해서 사용)

```
SCM-{XXX}을 지금 바로 실행해줘.

【구현 범위】
- 서비스     : services/{서비스명}/
- API 대상   : {엔드포인트 목록 — 예: GET /api/xxx/v1/items, POST /api/xxx/v1/items}
- 추가 파일  :
  - shared/contracts/{도메인}.openapi.yaml  (신규 엔드포인트 반영)
  - migration/flyway/V{N}__{설명}.sql       (스키마 변경 있을 경우만)
  - doc/adr/ADR-{N}-{설명}.md              (아키텍처 의사결정 있을 경우만)

【브랜치】
  feature/scm-{XXX}-{간단한-설명}
  (기준 브랜치: feature/to-be-dev-env-bootstrap)

【완료 기준 (DoD)】
- 5게이트 모두 exit code 0:
    build / unit-integration-test / contract-test / smoke-test / migration-dry-run
- 로그 내 [FAIL] 0건, [SKIP] 0건
- PR #{N} OPEN + 로컬 증적 코멘트 첨부 완료
- Issue #{M} CLOSED
- doc/QnA_보고서.md 업데이트 포함

【자동 처리 — 아래는 확인 없이 자동 진행해줘】
- 게이트 전부 PASS 시:
    PR 생성 → 로컬 증적 코멘트 첨부 → squash 머지 → Issue close →
    기준 브랜치 fast-forward → doc/QnA_보고서.md 커밋/푸시
- 전용 브랜치 삭제(로컬 + 원격)는 머지 직후 자동 처리
- add/commit/push 는 중간 확인 없이 실행

【의사결정 필요 시】
- 범위 밖 변경이 발생하거나 게이트 2회 재시도 후에도 실패하면 중단하고 상황을 알려줘.
  그 외 표준 작업은 자동 진행해줘.
```

---

## 작성 가이드

| 치환 항목 | 설명 | 예시 |
|---|---|---|
| `SCM-{XXX}` | 이슈 번호 | `SCM-210` |
| `{서비스명}` | 구현 대상 서비스 디렉터리 | `order-lot` |
| `{엔드포인트 목록}` | OpenAPI 계약 기준 | `GET /api/order-lot/v1/orders` |
| `V{N}` | 다음 Flyway 버전 번호 | `V8` |
| `PR #{N}` | 예상 PR 번호 (GitHub 최신 번호 + 1) | `#62` |
| `Issue #{M}` | 생성할 GitHub 이슈 번호 | `#61` |

---

## 단계별 자동 처리 흐름

```
프롬프트 입력
    │
    ▼
1. Issue 생성 (gh issue create)
    │
    ▼
2. 전용 브랜치 생성 + 체크아웃
    │
    ▼
3. 코드/문서 구현
    │
    ▼
4. 5게이트 실행 (RunId 자동 생성)
    │
    ├─ FAIL ──→ 1회 자동 복구 시도 → 재실행
    │               실패 시 중단 + 보고
    │
    └─ PASS ──→ 커밋/푸시
                    │
                    ▼
                PR 생성 + 증적 코멘트
                    │
                    ▼
                squash 머지
                    │
                    ▼
                Issue close
                    │
                    ▼
                기준 브랜치 동기화
                    │
                    ▼
                doc/QnA_보고서.md 업데이트 + 커밋/푸시
                    │
                    ▼
                완료 요약 출력
```

---

## 적용 전/후 비교

| 구분 | 기존 방식 (Q&A 횟수) | 최적화 후 |
|---|---|---|
| 준비사항 정리 요청 | Q_n (1회) | 프롬프트 내 범위 선언으로 대체 |
| 진행 승인 "예" | Q_n+1 (1회) | 자동 처리 선언으로 제거 |
| 커밋/푸시 승인 "예" | Q_n+2 (1회) | 자동 처리 선언으로 제거 |
| PR 생성 요청 | Q_n+3 (1회) | 자동 처리 선언으로 제거 |
| 머지 승인 | Q_n+4 (1회) | 자동 처리 선언으로 제거 |
| **합계** | **5회** | **1회** |
