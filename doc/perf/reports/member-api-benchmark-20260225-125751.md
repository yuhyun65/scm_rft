# Member API Benchmark

- Timestamp: 2026-02-25 12:57:51
- Base URL: http://localhost:8082
- Total Elapsed(s): 1.71

| Scenario | Requests | Success | Errors | Error Rate(%) | p50(ms) | p95(ms) | p99(ms) | TPS |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| status-only-page0 | 50 | 0 | 50 | 100 | 6.66 | 9.25 | 12.74 | 134.35 |
| keyword-prefix-page0 | 50 | 0 | 50 | 100 | 5.5 | 6.72 | 38.12 | 158.39 |
| status-keyword-page0 | 50 | 0 | 50 | 100 | 4.65 | 8.69 | 12.98 | 186.61 |
| status-only-page1000 | 50 | 0 | 50 | 100 | 4.3 | 5.27 | 5.89 | 217.8 |
