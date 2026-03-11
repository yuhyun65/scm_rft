param(
  [Parameter(Mandatory = $true)][string]$RunId,
  [string]$EvidenceRoot = "runbooks/evidence",
  [string]$ManifestOutputDir = "runbooks/evidence-manifest",
  [string]$ReleaseOutputDir = "migration/reports/releases",
  [switch]$VerifyOnly
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath([string]$relativePath) {
  $normalized = $relativePath.Replace("/", [System.IO.Path]::DirectorySeparatorChar)
  return Join-Path $repoRoot $normalized
}

function Get-RelativeRepoPath([string]$absolutePath) {
  $base = [System.IO.Path]::GetFullPath($repoRoot)
  $full = [System.IO.Path]::GetFullPath($absolutePath)
  $baseUri = New-Object System.Uri(($base.TrimEnd('\') + '\'))
  $fullUri = New-Object System.Uri($full)
  return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($fullUri).ToString())
}

function Verify-Manifest([string]$manifestPath) {
  if (-not (Test-Path $manifestPath)) {
    throw "Manifest not found: $manifestPath"
  }

  $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
  $missing = 0
  $mismatch = 0

  foreach ($item in $manifest.files) {
    $target = Resolve-RepoPath $item.path
    if (-not (Test-Path $target)) {
      Write-Host "[MISS] $($item.path)"
      $missing++
      continue
    }

    $actual = (Get-FileHash -Algorithm SHA256 $target).Hash.ToLower()
    if ($actual -ne $item.sha256) {
      Write-Host "[MISMATCH] $($item.path)"
      $mismatch++
    }
  }

  if ($missing -gt 0 -or $mismatch -gt 0) {
    throw "Manifest verification failed. missing=$missing mismatch=$mismatch"
  }

  Write-Host "[OK] manifest verified. files=$($manifest.fileCount)"
}

$manifestDir = Resolve-RepoPath $ManifestOutputDir
$releaseDir = Resolve-RepoPath $ReleaseOutputDir
$manifestJsonPath = Join-Path $manifestDir "$RunId-manifest.json"
$manifestMdPath = Join-Path $manifestDir "$RunId-manifest.md"
$releaseMdPath = Join-Path $releaseDir "$RunId-evidence-summary.md"
$releaseJsonPath = Join-Path $releaseDir "$RunId-evidence-summary.json"

if ($VerifyOnly) {
  Verify-Manifest $manifestJsonPath
  exit 0
}

$evidenceDir = Join-Path (Resolve-RepoPath $EvidenceRoot) $RunId
if (-not (Test-Path $evidenceDir)) {
  throw "Evidence directory not found: $evidenceDir"
}

$evidenceFiles = Get-ChildItem $evidenceDir -File -Recurse | Sort-Object FullName
if ($evidenceFiles.Count -eq 0) {
  throw "No evidence files found under: $evidenceDir"
}

New-Item -ItemType Directory -Force $manifestDir | Out-Null
New-Item -ItemType Directory -Force $releaseDir | Out-Null

$branch = (& git -C $repoRoot rev-parse --abbrev-ref HEAD).Trim()
$commit = (& git -C $repoRoot rev-parse HEAD).Trim()
$generatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssK")

$manifestFiles = @()
foreach ($file in $evidenceFiles) {
  $hash = (Get-FileHash -Algorithm SHA256 $file.FullName).Hash.ToLower()
  $manifestFiles += [ordered]@{
    path = (Get-RelativeRepoPath $file.FullName).Replace('\', '/')
    sha256 = $hash
    sizeBytes = $file.Length
    lastWriteTimeUtc = $file.LastWriteTimeUtc.ToString("yyyy-MM-ddTHH:mm:ssZ")
  }
}

$manifest = [ordered]@{
  runId = $RunId
  generatedAt = $generatedAt
  branch = $branch
  commit = $commit
  evidenceRoot = (Get-RelativeRepoPath $evidenceDir).Replace('\', '/')
  fileCount = $manifestFiles.Count
  files = $manifestFiles
}

$manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestJsonPath -Encoding UTF8

$md = @()
$md += "# Evidence Manifest"
$md += ""
$md += "- RunId: $RunId"
$md += "- GeneratedAt: $generatedAt"
$md += "- Branch: $branch"
$md += "- Commit: $commit"
$md += "- EvidenceRoot: $($manifest.evidenceRoot)"
$md += "- FileCount: $($manifest.fileCount)"
$md += ""
$md += "## Files"
$md += "| Path | SHA256 | SizeBytes | LastWriteUtc |"
$md += "|---|---|---:|---|"
foreach ($item in $manifestFiles) {
  $md += "| $($item.path) | $($item.sha256) | $($item.sizeBytes) | $($item.lastWriteTimeUtc) |"
}
$md += ""
$md += "## Verify"
$md += "Run:"
$md += "powershell -ExecutionPolicy Bypass -File .\\scripts\\publish-evidence-manifest.ps1 -RunId $RunId -VerifyOnly"
Set-Content -Path $manifestMdPath -Value $md -Encoding UTF8

$releaseSummary = [ordered]@{
  runId = $RunId
  generatedAt = $generatedAt
  branch = $branch
  commit = $commit
  manifestJson = (Get-RelativeRepoPath $manifestJsonPath).Replace('\', '/')
  manifestMd = (Get-RelativeRepoPath $manifestMdPath).Replace('\', '/')
  fileCount = $manifestFiles.Count
}
$releaseSummary | ConvertTo-Json -Depth 6 | Set-Content -Path $releaseJsonPath -Encoding UTF8

$releaseMd = @()
$releaseMd += "# Release Evidence Summary"
$releaseMd += ""
$releaseMd += "- RunId: $RunId"
$releaseMd += "- GeneratedAt: $generatedAt"
$releaseMd += "- Branch: $branch"
$releaseMd += "- Commit: $commit"
$releaseMd += "- FileCount: $($manifestFiles.Count)"
$releaseMd += "- Manifest JSON: $($releaseSummary.manifestJson)"
$releaseMd += "- Manifest MD: $($releaseSummary.manifestMd)"
Set-Content -Path $releaseMdPath -Value $releaseMd -Encoding UTF8

Verify-Manifest $manifestJsonPath

Write-Host "[OK] manifest published: $manifestJsonPath"
Write-Host "[OK] manifest summary: $manifestMdPath"
Write-Host "[OK] release summary: $releaseMdPath"
