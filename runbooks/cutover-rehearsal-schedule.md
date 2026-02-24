# Cutover Rehearsal Schedule and Go-NoGo Criteria

## Rehearsal Calendar (Template)

| Rehearsal | Target Date | Scope | Owner | Exit Condition |
|---|---|---|---|---|
| R1 | 2026-03-06 | full dry-run + data validation | Dev + Codex | end-to-end 절차 누락 없음 |
| R2 | 2026-03-13 | 장애/복구 시나리오 포함 | Dev + Codex | 롤백 시간 30분 이내 |
| R3 | 2026-03-20 | cutover 동일 조건 리허설 | Dev + Codex | Go/No-Go 기준 전부 충족 |

## Go / No-Go Gate

### Data
- 행 수 오차율: 0%
- 합계 검증 오차율: 0%
- 샘플 검증 성공률: 100%

### API / Function
- P0 API smoke pass: 100%
- 인증/권한 시나리오 pass: 100%
- 파일 업로드/다운로드 pass: 100%

### Performance / Stability
- 핵심 API P95: 사전 기준치 이내
- 컷오버 중 치명 장애: 0건
- 모니터링 블라인드 구간: 0분

### Security / Operation
- secret scan/sast high 이상 미해결: 0건
- 백업/복구 리허설 성공: 100%
- 비상 연락체계 점검: 완료
