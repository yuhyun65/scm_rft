.PHONY: dev-up dev-up-gateway dev-down dev-down-v staging-up staging-down staging-down-v check-prereqs roadmap-report agentic-new-run agentic-validate-run ci-build ci-test ci-contract ci-lint ci-security ci-migration ci-smoke migrate-dry-run migrate-validate rehearsal-run db-backup db-restore gradle-build gradle-test run-auth run-member run-gateway new-rehearsal-record new-migration-report

check-prereqs:
	powershell -ExecutionPolicy Bypass -File .\scripts\check-prereqs.ps1

roadmap-report:
	powershell -ExecutionPolicy Bypass -File .\scripts\roadmap-report.ps1

dev-up:
	powershell -ExecutionPolicy Bypass -File .\scripts\dev-up.ps1

dev-up-gateway:
	powershell -ExecutionPolicy Bypass -File .\scripts\dev-up.ps1 -WithGateway

dev-down:
	powershell -ExecutionPolicy Bypass -File .\scripts\dev-down.ps1

dev-down-v:
	powershell -ExecutionPolicy Bypass -File .\scripts\dev-down.ps1 -RemoveVolumes

staging-up:
	powershell -ExecutionPolicy Bypass -File .\scripts\staging-up.ps1

staging-down:
	powershell -ExecutionPolicy Bypass -File .\scripts\staging-down.ps1

staging-down-v:
	powershell -ExecutionPolicy Bypass -File .\scripts\staging-down.ps1 -RemoveVolumes

agentic-new-run:
	powershell -ExecutionPolicy Bypass -File .\scripts\agentic-new-run.ps1 -IssueId $(ISSUE_ID) -Service $(SERVICE)

agentic-validate-run:
	powershell -ExecutionPolicy Bypass -File .\scripts\agentic-validate-run.ps1 -RunDir $(RUN_DIR)

ci-build:
	powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate build

ci-test:
	powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate unit-integration-test

ci-contract:
	powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate contract-test

ci-lint:
	powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate lint-static-analysis

ci-security:
	powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate security-scan

ci-migration:
	powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate migration-dry-run

ci-smoke:
	powershell -ExecutionPolicy Bypass -File .\scripts\ci-run-gate.ps1 -Gate smoke-test

migrate-dry-run:
	powershell -ExecutionPolicy Bypass -File .\migration\scripts\dry-run.ps1

migrate-validate:
	powershell -ExecutionPolicy Bypass -File .\migration\verify\validate-migration.ps1

rehearsal-run:
	powershell -ExecutionPolicy Bypass -File .\scripts\rehearsal-run.ps1

db-backup:
	powershell -ExecutionPolicy Bypass -File .\scripts\backup-db.ps1 -Database $(DB)

db-restore:
	powershell -ExecutionPolicy Bypass -File .\scripts\restore-db.ps1 -Database $(DB) -BackupFile $(BACKUP_FILE)

gradle-build:
	.\gradlew.bat build

gradle-test:
	.\gradlew.bat test

run-auth:
	.\gradlew.bat :services:auth:bootRun

run-member:
	.\gradlew.bat :services:member:bootRun

run-gateway:
	.\gradlew.bat :services:gateway:bootRun

new-rehearsal-record:
	powershell -ExecutionPolicy Bypass -File .\scripts\new-rehearsal-record.ps1 -RehearsalId $(REHEARSAL_ID)

new-migration-report:
	powershell -ExecutionPolicy Bypass -File .\scripts\new-migration-report.ps1 -RehearsalId $(REHEARSAL_ID)
