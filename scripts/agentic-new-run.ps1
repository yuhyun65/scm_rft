param(
  [Parameter(Mandatory = $true)][string]$IssueId,
  [Parameter(Mandatory = $true)][string]$Service,
  [string]$RunId = "",
  [string]$OutputRoot = "agentic/runs"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$resolvedOutputRoot = if ([System.IO.Path]::IsPathRooted($OutputRoot)) { $OutputRoot } else { Join-Path $repoRoot $OutputRoot }

if ([string]::IsNullOrWhiteSpace($RunId)) {
  $RunId = "{0}-{1}" -f $IssueId, (Get-Date -Format "yyyyMMdd-HHmmss")
}

$runDir = Join-Path $resolvedOutputRoot $RunId
$artifactDir = Join-Path $runDir "artifacts"

if (Test-Path $runDir) {
  throw "Run directory already exists: $runDir"
}

New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null

$branch = ""
try {
  $branch = (git -C $repoRoot branch --show-current).Trim()
}
catch {
  $branch = "unknown"
}

$runInfo = [ordered]@{
  run_id = $RunId
  issue_id = $IssueId
  service = $Service
  branch = $branch
  created_at = (Get-Date).ToString("s")
  status = [ordered]@{
    architect = "pending"
    build = "pending"
    test = "pending"
    security = "pending"
    migration = "pending"
    release = "pending"
  }
  logs = @()
}

$runJsonPath = Join-Path $runDir "run.json"
$runInfo | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $runJsonPath

$steps = @(
  @{ index = "01"; name = "architect"; mission = "define service boundaries and API contracts" },
  @{ index = "02"; name = "build"; mission = "implement service and migration code" },
  @{ index = "03"; name = "test"; mission = "strengthen contract/integration/regression tests" },
  @{ index = "04"; name = "security"; mission = "check security baseline and secrets" },
  @{ index = "05"; name = "migration"; mission = "automate migration and data validation" },
  @{ index = "06"; name = "release"; mission = "finalize cutover and release artifacts" }
)

foreach ($step in $steps) {
  $stepFile = Join-Path $runDir ("{0}-{1}.md" -f $step.index, $step.name)
  @"
# Step $($step.index): $($step.name)

- status: pending
- issue: $IssueId
- service: $Service
- branch: $branch
- mission: $($step.mission)

## input
- 

## output
- 

## notes
- 
"@ | Set-Content -Encoding UTF8 $stepFile
}

$templateDir = Join-Path $repoRoot "agentic/templates"
$templateMap = @{
  "adr.md" = "adr.md"
  "openapi.yaml" = "openapi.yaml"
  "migration-report.md" = "migration-report.md"
  "cutover-checklist.md" = "cutover-checklist.md"
  "rollback-playbook.md" = "rollback-playbook.md"
  "release-note.md" = "release-note.md"
}

foreach ($k in $templateMap.Keys) {
  Copy-Item -Path (Join-Path $templateDir $k) -Destination (Join-Path $artifactDir $templateMap[$k]) -Force
}

Write-Host "Agentic run created:"
Write-Host $runDir
