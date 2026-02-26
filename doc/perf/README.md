# Member Search Performance Kit

This directory stores preparation artifacts and reports for large-sample member search performance tests.

## Standard report location
- `doc/perf/reports/`

## Recommended run order
1. Start local infra:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\dev-up.ps1`
2. Prepare DB schema (V1~V5):
   - `powershell -ExecutionPolicy Bypass -File .\scripts\perf-member-prepare-db.ps1`
3. Seed sample data:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\perf-member-seed.ps1 -RowCount 100000`
   - `powershell -ExecutionPolicy Bypass -File .\scripts\perf-member-seed.ps1 -RowCount 500000`
   - `powershell -ExecutionPolicy Bypass -File .\scripts\perf-member-seed.ps1 -RowCount 1000000`
4. Collect SQL plan/statistics:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\perf-member-sql-benchmark.ps1`
5. Run API latency benchmark (member service must be running):
   - `powershell -ExecutionPolicy Bypass -File .\scripts\perf-member-api-benchmark.ps1`

## SQL client note
- If host `sqlcmd` is not installed, scripts use container sqlcmd:
  - `docker exec scm-sqlserver /opt/mssql-tools18/bin/sqlcmd ...`

## Output artifacts
- SQL benchmark log: `doc/perf/reports/member-sql-benchmark-*.log`
- API benchmark markdown/json: `doc/perf/reports/member-api-benchmark-*.md|json`
- Final analysis report: use `doc/perf/member-search-benchmark-template.md`

