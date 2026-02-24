.PHONY: dev-up dev-down dev-down-v check-prereqs agentic-new-run agentic-validate-run

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
