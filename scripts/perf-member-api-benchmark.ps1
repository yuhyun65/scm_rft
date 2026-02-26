param(
  [string]$BaseUrl = "http://localhost:8082",
  [int]$WarmupRequests = 20,
  [int]$MeasureRequestsPerScenario = 200,
  [string]$OutputDir = "doc/perf/reports",
  [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

if ($WarmupRequests -lt 0) {
  throw "WarmupRequests must be >= 0."
}
if ($MeasureRequestsPerScenario -lt 1) {
  throw "MeasureRequestsPerScenario must be >= 1."
}

$resolvedOutputDir = if ([System.IO.Path]::IsPathRooted($OutputDir)) { $OutputDir } else { Join-Path $RepoRoot $OutputDir }
New-Item -ItemType Directory -Path $resolvedOutputDir -Force | Out-Null

$scenarios = @(
  @{ name = "status-only-page0"; path = "/api/member/v1/members?status=ACTIVE&page=0&size=20" },
  @{ name = "keyword-prefix-page0"; path = "/api/member/v1/members?keyword=M0001&status=&page=0&size=20" },
  @{ name = "status-keyword-page0"; path = "/api/member/v1/members?status=ACTIVE&keyword=ALPHA&page=0&size=20" },
  @{ name = "status-only-page1000"; path = "/api/member/v1/members?status=ACTIVE&page=1000&size=20" }
)

function Invoke-OneRequest {
  param([string]$Url)
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $ok = $true
  $statusCode = 0
  try {
    $response = Invoke-WebRequest -Uri $Url -Method GET -UseBasicParsing -TimeoutSec 30
    $statusCode = [int]$response.StatusCode
    if ($statusCode -lt 200 -or $statusCode -ge 300) {
      $ok = $false
    }
  }
  catch {
    $ok = $false
  }
  finally {
    $sw.Stop()
  }

  return [pscustomobject]@{
    ok = $ok
    statusCode = $statusCode
    latencyMs = [double]$sw.Elapsed.TotalMilliseconds
  }
}

function Get-Percentile {
  param([double[]]$Values, [double]$P)
  if (-not $Values -or $Values.Count -eq 0) { return 0.0 }
  $sorted = $Values | Sort-Object
  $rank = [Math]::Ceiling(($P / 100.0) * $sorted.Count)
  $index = [Math]::Max(1, [int]$rank) - 1
  return [double]$sorted[$index]
}

$results = @()
$overallStart = Get-Date

foreach ($scenario in $scenarios) {
  $url = "{0}{1}" -f $BaseUrl.TrimEnd('/'), $scenario.path
  Write-Host "[INFO] Scenario: $($scenario.name)"

  for ($i = 0; $i -lt $WarmupRequests; $i++) {
    Invoke-OneRequest -Url $url | Out-Null
  }

  $samples = @()
  $scenarioStart = Get-Date
  for ($i = 0; $i -lt $MeasureRequestsPerScenario; $i++) {
    $samples += Invoke-OneRequest -Url $url
  }
  $scenarioElapsed = (Get-Date) - $scenarioStart

  $latencies = @($samples | ForEach-Object { [double]$_.latencyMs })
  $errorCount = @($samples | Where-Object { -not $_.ok }).Count
  $successCount = $MeasureRequestsPerScenario - $errorCount
  $tps = if ($scenarioElapsed.TotalSeconds -gt 0) { [Math]::Round($MeasureRequestsPerScenario / $scenarioElapsed.TotalSeconds, 2) } else { 0 }

  $results += [pscustomobject]@{
    scenario = $scenario.name
    requestCount = $MeasureRequestsPerScenario
    successCount = $successCount
    errorCount = $errorCount
    errorRate = [Math]::Round(($errorCount / [double]$MeasureRequestsPerScenario) * 100.0, 2)
    p50Ms = [Math]::Round((Get-Percentile -Values $latencies -P 50), 2)
    p95Ms = [Math]::Round((Get-Percentile -Values $latencies -P 95), 2)
    p99Ms = [Math]::Round((Get-Percentile -Values $latencies -P 99), 2)
    tps = $tps
  }
}

$overallElapsed = (Get-Date) - $overallStart
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$jsonPath = Join-Path $resolvedOutputDir ("member-api-benchmark-{0}.json" -f $timestamp)
$mdPath = Join-Path $resolvedOutputDir ("member-api-benchmark-{0}.md" -f $timestamp)

$results | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonPath -Encoding UTF8

$md = @()
$md += "# Member API Benchmark"
$md += ""
$md += "- Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
$md += "- Base URL: $BaseUrl"
$md += "- Total Elapsed(s): $([Math]::Round($overallElapsed.TotalSeconds, 2))"
$md += ""
$md += "| Scenario | Requests | Success | Errors | Error Rate(%) | p50(ms) | p95(ms) | p99(ms) | TPS |"
$md += "|---|---:|---:|---:|---:|---:|---:|---:|---:|"
foreach ($r in $results) {
  $md += "| $($r.scenario) | $($r.requestCount) | $($r.successCount) | $($r.errorCount) | $($r.errorRate) | $($r.p50Ms) | $($r.p95Ms) | $($r.p99Ms) | $($r.tps) |"
}

$md -join "`r`n" | Set-Content -Path $mdPath -Encoding UTF8

Write-Host ("[OK] API benchmark report: {0}" -f $mdPath)
Write-Host ("[OK] API benchmark raw json: {0}" -f $jsonPath)

