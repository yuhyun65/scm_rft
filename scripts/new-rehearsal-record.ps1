param(
  [Parameter(Mandatory = $true)][string]$RehearsalId
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$template = Join-Path $repoRoot "runbooks/rehearsals/rehearsal-record-template.md"
$outputDir = Join-Path $repoRoot "runbooks/rehearsals"

if (-not (Test-Path $template)) {
  throw "template not found: $template"
}

$outputPath = Join-Path $outputDir ("{0}-{1}.md" -f $RehearsalId, (Get-Date -Format "yyyyMMdd"))
Copy-Item -Path $template -Destination $outputPath -Force
Write-Host "[OK] created rehearsal record: $outputPath"
