.PHONY: dev-up dev-down dev-down-v check-prereqs agentic-new-run agentic-validate-run ci-build ci-test ci-contract ci-lint ci-security ci-migration ci-smoke

check-prereqs:
	powershell -ExecutionPolicy Bypass -File .\scripts\check-prereqs.ps1

dev-up:
	powershell -ExecutionPolicy Bypass -File .\scripts\dev-up.ps1

dev-down:
	powershell -ExecutionPolicy Bypass -File .\scripts\dev-down.ps1

dev-down-v:
	powershell -ExecutionPolicy Bypass -File .\scripts\dev-down.ps1 -RemoveVolumes

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
