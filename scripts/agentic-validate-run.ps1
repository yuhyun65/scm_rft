param(
  [Parameter(Mandatory = $true)][string]$RunDir
)

$ErrorActionPreference = "Stop"

$resolvedRunDir = Resolve-Path $RunDir
$runJsonPath = Join-Path $resolvedRunDir "run.json"
$artifactDir = Join-Path $resolvedRunDir "artifacts"

if (-not (Test-Path $runJsonPath)) {
  throw "run.json not found: $runJsonPath"
}

if (-not (Test-Path $artifactDir)) {
  throw "artifacts directory not found: $artifactDir"
}

$requiredArtifacts = @(
  "adr.md",
  "openapi.yaml",
  "migration-report.md",
  "cutover-checklist.md",
  "rollback-playbook.md",
  "release-note.md"
)

$missing = @()
$empty = @()

foreach ($file in $requiredArtifacts) {
  $path = Join-Path $artifactDir $file
  if (-not (Test-Path $path)) {
    $missing += $file
    continue
  }

  $content = Get-Content -Raw -Encoding UTF8 $path
  if ([string]::IsNullOrWhiteSpace($content)) {
    $empty += $file
  }
}

if ($missing.Count -gt 0) {
  Write-Host "[ERROR] Missing artifacts:"
  $missing | ForEach-Object { Write-Host ("- {0}" -f $_) }
  exit 1
}

if ($empty.Count -gt 0) {
  Write-Host "[ERROR] Empty artifacts:"
  $empty | ForEach-Object { Write-Host ("- {0}" -f $_) }
  exit 1
}

Write-Host "[OK] Run artifacts are valid."
Write-Host ("Run directory: {0}" -f $resolvedRunDir)
