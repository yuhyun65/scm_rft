param(
  [string]$EvidenceDir = "runbooks/evidence/SCM-231",
  [int]$TimeoutSec = 120,
  [int]$PollSec = 2
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

$targets = @(
  @{ Name = "auth"; Url = "http://localhost:8081/actuator/health" },
  @{ Name = "member"; Url = "http://localhost:8082/actuator/health" },
  @{ Name = "board"; Url = "http://localhost:8083/actuator/health" },
  @{ Name = "quality-doc"; Url = "http://localhost:8084/actuator/health" },
  @{ Name = "order-lot"; Url = "http://localhost:8085/actuator/health" },
  @{ Name = "inventory"; Url = "http://localhost:8086/actuator/health" },
  @{ Name = "file"; Url = "http://localhost:8087/actuator/health" },
  @{ Name = "report"; Url = "http://localhost:8088/actuator/health" },
  @{ Name = "gateway"; Url = "http://localhost:18080/actuator/health" }
)

$evDir = Join-Path $repoRoot $EvidenceDir
New-Item -ItemType Directory -Force -Path $evDir | Out-Null

$results = @()
foreach ($t in $targets) {
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  $attempt = 0
  $lastError = ""
  $status = "DOWN"

  while ((Get-Date) -lt $deadline) {
    $attempt += 1
    try {
      $resp = Invoke-RestMethod -Method Get -Uri $t.Url -TimeoutSec 5
      if ($resp.status -and "$($resp.status)".ToUpperInvariant() -eq "UP") {
        $status = "UP"
        break
      }
      $lastError = "status=$($resp.status)"
    }
    catch {
      $lastError = $_.Exception.Message
    }
    Start-Sleep -Seconds $PollSec
  }

  $results += [pscustomobject]@{
    service = $t.Name
    url = $t.Url
    status = $status
    attempt = $attempt
    result = $(if ($status -eq "UP") { "PASS" } else { "FAIL" })
    last_error = $lastError
  }
}

$jsonPath = Join-Path $evDir "health-check-summary.json"
$mdPath = Join-Path $evDir "health-check-summary.md"
$results | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 $jsonPath

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# SCM-231 Health Check Summary")
$md.Add("")
$md.Add("- GeneratedAt: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")")
$md.Add("")
$md.Add("| Service | Url | Status | Result | Attempt | LastError |")
$md.Add("|---|---|---|---|---:|---|")
foreach ($r in $results) {
  $err = if ([string]::IsNullOrWhiteSpace($r.last_error)) { "-" } else { ($r.last_error -replace "\|", "/") }
  $md.Add("| $($r.service) | $($r.url) | $($r.status) | $($r.result) | $($r.attempt) | $err |")
}
$md | Set-Content -Encoding UTF8 $mdPath

$failCount = @($results | Where-Object { $_.result -eq "FAIL" }).Count
if ($failCount -gt 0) {
  throw "health check failed: $failCount service(s) are not UP. see $mdPath"
}

Write-Host ("[OK] health check passed for {0} services" -f $results.Count)
Write-Host ("[OK] summary: {0}" -f $mdPath)
