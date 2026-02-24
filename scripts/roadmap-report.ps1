param(
  [string]$ProgressPath = "doc/roadmap/progress.json",
  [switch]$FailIfOutOfOrder
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$resolvedPath = if ([System.IO.Path]::IsPathRooted($ProgressPath)) { $ProgressPath } else { Join-Path $repoRoot $ProgressPath }

if (-not (Test-Path $resolvedPath)) {
  throw "progress file not found: $resolvedPath"
}

$data = Get-Content -Raw -Encoding UTF8 $resolvedPath | ConvertFrom-Json
$phases = @($data.phases)

Write-Host ("Roadmap Progress Report ({0})" -f $data.updated_at)
Write-Host ""

$blockedOutOfOrder = $false
$encounteredPlanned = $false

foreach ($p in $phases) {
  $items = @($p.items)
  $total = $items.Count
  $done = @($items | Where-Object { $_.done -eq $true }).Count
  $percent = 0
  if ($total -gt 0) { $percent = [math]::Round(($done / $total) * 100, 0) }

  Write-Host ("- {0}: {1} ({2}/{3}, {4}%)" -f $p.id, $p.status, $done, $total, $percent)
  Write-Host ("  title: {0}" -f $p.title)

  if ($p.status -ne "completed") {
    $encounteredPlanned = $true
  }
  elseif ($encounteredPlanned) {
    $blockedOutOfOrder = $true
  }
}

if ($FailIfOutOfOrder -and $blockedOutOfOrder) {
  throw "Out-of-order completion detected in phase statuses."
}
