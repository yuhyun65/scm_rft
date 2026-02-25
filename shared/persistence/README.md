# Persistence Baseline (SCM-205)

This directory defines the shared DB standard for all SCM_RFT services.

## Standard runtime properties
- `SCM_DB_URL`
- `SCM_DB_USER`
- `SCM_DB_PASSWORD`
- `SCM_DB_DRIVER`
- `SCM_FLYWAY_ENABLED`
- `SCM_FLYWAY_LOCATIONS`
- `SCM_FLYWAY_TABLE`

## Current baseline decisions
- Every service includes `spring-boot-starter-data-jdbc`.
- Flyway is included in every service to keep schema migration behavior consistent.
- SQL Server driver is the target runtime driver.
- H2 is included for local/default bootstrap without external DB dependencies.
- Default Flyway mode is disabled in local profile (`SCM_FLYWAY_ENABLED=false`) to avoid accidental migrations.

## Migration source
- Canonical SQL scripts are in `migration/flyway`.
- Use `scripts/ci-run-gate.ps1 -Gate migration-dry-run` before PR merge.
