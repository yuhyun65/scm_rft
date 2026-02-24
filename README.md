# SCM_RFT

SCM 레거시(`HISCM`)를 MSA로 Big-Bang 전환하기 위한 리팩토링 저장소입니다.
신규 개발환경은 `doc/scm_rft_design.md`의 3장(TO-BE 개발환경) 기준으로 구성합니다.

## 개발 브랜치 전략
- 기본 브랜치: `main`
- 기능 개발 브랜치: `feature/*`
- 현재 개발환경 재구축 브랜치: `feature/to-be-dev-env-bootstrap`

## TO-BE 개발환경 빠른 시작 (Windows PowerShell)
1. 필수 도구 설치 확인
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check-prereqs.ps1
```

버전이 잠금 정책과 다르면 세션에 잠금 버전 적용
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\use-toolchain.ps1
```

2. 환경 변수 파일 준비
```powershell
Copy-Item .env.example .env
```

3. 로컬 통합 인프라 실행
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev-up.ps1
```

4. 로컬 통합 인프라 중지
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev-down.ps1
```

## 기본 접속 정보
- Grafana: `http://localhost:3000`
- Prometheus: `http://localhost:9090`
- Loki: `http://localhost:3100`
- Tempo: `http://localhost:3200`
- RabbitMQ UI: `http://localhost:15672`
- SQL Server: `localhost:1433`
- Redis: `localhost:6379`

## 저장소 구조
```text
SCM_RFT/
  HISCM/          # 레거시 원본
  services/       # MSA 서비스 코드
  shared/         # 공통 라이브러리/계약
  infra/          # Docker/관측/인프라 설정
  migration/      # 데이터 이관 스크립트/검증
  runbooks/       # 컷오버/운영 절차
  scripts/        # 개발 부트스트랩 스크립트
  doc/            # 설계/분석/QnA 문서
```

## 참고 문서
- `doc/scm_rft_design.md`
- `doc/QnA_보고서.md`
- `toolchain.lock.json`
