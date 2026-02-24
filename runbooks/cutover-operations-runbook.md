# Cutover Operations Runbook

## Objective
- execute Big-Bang cutover with controllable risk and immediate rollback path

## Runtime Controls
- real-time monitoring dashboard:
  - Grafana: cutover dashboard
  - Prometheus/Loki/Tempo linked datasource
- gateway protection:
  - apply `infra/gateway/policies/cutover-isolation.yaml`
  - enable write protection on critical routes

## Cutover Steps
1. Go/No-Go approval
2. freeze write traffic (gateway switch)
3. final incremental migration
4. smoke verification
5. open new system traffic

## Rollback Steps
1. activate emergency stop on gateway
2. restore DB from latest backup (`scripts/restore-db.ps1`)
3. reopen legacy traffic
4. collect incident timeline and recovery report

## Required Logs
- trace id from gateway
- migration run id
- backup file name used for rollback point
