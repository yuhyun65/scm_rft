.PHONY: dev-up dev-down dev-down-v check-prereqs

check-prereqs:
	powershell -ExecutionPolicy Bypass -File .\scripts\check-prereqs.ps1

dev-up:
	powershell -ExecutionPolicy Bypass -File .\scripts\dev-up.ps1

dev-down:
	powershell -ExecutionPolicy Bypass -File .\scripts\dev-down.ps1

dev-down-v:
	powershell -ExecutionPolicy Bypass -File .\scripts\dev-down.ps1 -RemoveVolumes
