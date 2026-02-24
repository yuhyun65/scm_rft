param(
  [Parameter(Mandatory = $true)][string]$RehearsalId,
  [string]$Author = "Dev+Codex"
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$template = Join-Path $repoRoot "migration/templates/validation-report-template.md"
$reportDir = Join-Path $repoRoot "migration/reports"

if (-not (Test-Path $template)) {
  throw "template not found: $template"
}

New-Item -ItemType Directory -Force -Path $reportDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputPath = Join-Path $reportDir ("validation-{0}-{1}.md" -f $RehearsalId, $timestamp)

$content = Get-Content -Raw -Encoding UTF8 $template
$content = $content.Replace("__REHEARSAL_ID__", $RehearsalId)
$content = $content.Replace("__GENERATED_AT__", (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$content = $content.Replace("__AUTHOR__", $Author)

Set-Content -Path $outputPath -Value $content -Encoding UTF8
Write-Host "[OK] created migration validation report: $outputPath"
