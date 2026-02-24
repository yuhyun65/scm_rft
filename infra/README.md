# Infra

TO-BE 개발환경의 로컬 인프라 정의를 관리합니다.

## 포함 범위
- `docker-compose.yml`에서 사용하는 공통 인프라 설정
- `docker-compose.staging.yml` 기반 staging rehearsal 오버레이
- 관측 스택 설정(Prometheus, Loki, Tempo, Grafana provisioning)
- API Gateway cutover isolation policy 템플릿
