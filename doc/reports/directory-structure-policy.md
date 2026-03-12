# Directory Structure Policy (2026-03-12)

## Root layout
- services/: domain services source code only
- shared/contracts/: OpenAPI and shared contracts
- migration/reports/releases/: committed release-grade migration reports
- unbooks/: operational runbooks and tracked manifests
- doc/: architecture, roadmap, PR notes, and dated progress reports
- scripts/: automation scripts
- infra/, gateway/, sql/: platform/policy/sql assets

## Generated artifact rules
- Keep generated outputs out of Git: .gradle-user/, services/*/bin/, services/*/build/, unbooks/evidence/.
- Keep evidence manifests in Git: unbooks/evidence-manifest/.
- Keep release-grade migration results in Git: migration/reports/releases/.

## Legacy asset rule (HISCM/)
- Treat HISCM/ as reference-only legacy mirror.
- No new feature code under HISCM/.
- New work must be created under services/, shared/, unbooks/, migration/, doc/.

## Naming rule
- Date report files use YYYYMMDD_<topic>.md under doc/reports/<category>/.
- Release process docs use kebab-case under doc/releases/.
