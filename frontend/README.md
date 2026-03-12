# Frontend Workspace

This workspace is the baseline for SCM frontend modernization (`SCM-245`).

## Packages
- `apps/web-portal`: React + Vite web app
- `packages/api-client`: generated client metadata from `shared/contracts/*.openapi.yaml`
- `packages/ui`: shared UI helpers

## Commands
```powershell
corepack pnpm -C .\frontend install
corepack pnpm -C .\frontend -r build
corepack pnpm -C .\frontend -r test
corepack pnpm -C .\frontend -r lint
corepack pnpm -C .\frontend --filter @scm-rft/api-client contract:generate
corepack pnpm -C .\frontend --filter @scm-rft/web-portal dev
```
