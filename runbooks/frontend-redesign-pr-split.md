# Frontend Redesign PR Split

## Branch
- Working branch: `feature/scm-252-frontend-redesign-foundation`

## Validation Baseline
- `frontend build`: PASS
- `frontend unit test`: PASS (`5 files`, `16 tests`)
- `frontend-dev` browser smoke: PASS
- Browser smoke evidence: `runbooks/evidence/SCM-252-BROWSER-SMOKE-20260317-113505/`

## PR-1: Frontend Routed Shell Foundation
- Suggested issue/PR key: `SCM-252`
- Goal: move the current MVP page into a routed app shell that still keeps the local web flow runnable.
- Include:
  - `frontend/apps/web-portal/package.json`
  - `frontend/pnpm-lock.yaml`
  - `frontend/apps/web-portal/src/App.tsx`
  - `frontend/apps/web-portal/src/styles.css`
  - `frontend/apps/web-portal/vite.config.ts`
  - `frontend/apps/web-portal/src/components/**`
  - `frontend/apps/web-portal/src/layouts/**`
  - `frontend/apps/web-portal/src/pages/**`
  - `frontend/apps/web-portal/src/store/**`
- DoD:
  - `corepack pnpm -C .\frontend --filter @scm-rft/web-portal build` PASS
  - `corepack pnpm -C .\frontend --filter @scm-rft/web-portal test` PASS
  - `frontend-dev` browser smoke PASS

## PR-2: Frontend Process / Design Docs
- Suggested issue/PR key: `SCM-253`
- Goal: separate process/design/support docs from the runnable UI change set.
- Include:
  - `doc/frontend_process.md`
  - `doc/ui-design-proposal.html`
  - `doc/ui-implementation-plan.md`
  - `runbooks/agentic-orchestration.md`
  - `runbooks/prompt-templates/**`
  - `doc/HISCM_MSA_개발이력보고서.docx` only if this document is intended to be versioned in SCM_RFT
- DoD:
  - doc paths and ownership are clear
  - no runtime code mixed into the doc PR

## Exclude From PR
- `_tmp_*`
- `frontend/_tmp_*`
- generated artifacts outside intentional source files
- any local scratch files without long-term ownership

## Merge Order
1. `SCM-252` routed shell foundation
2. `SCM-253` design/process docs

## Notes
- The current routed-shell WIP is buildable and testable after aligning router initialization and the Vitest environment.
- The current browser smoke required backend readiness up to roughly 2 minutes, so use the longer health timeout when reproducing the smoke.
