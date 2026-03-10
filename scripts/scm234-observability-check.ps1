[CmdletBinding()]
param(
  [string]$RunId = ("SCM-234-" + (Get-Date -Format "yyyyMMdd-HHmmss")),
  [string]$EvidenceRoot = "runbooks/evidence",
  [string]$Database = "MES_HI",
  [string]$SqlContainerName = "",
  [string]$EnvFile = "",
  [string]$PrometheusBaseUrl = "",
  [string]$RabbitApiBaseUrl = "",
  [string]$RabbitUser = "",
  [string]$RabbitPassword = "",
  [switch]$FailOnThreshold
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

function Select-Endpoint {
  param(
    [Parameter(Mandatory = $true)][string[]]$Candidates,
    [Parameter(Mandatory = $true)][string]$HealthPath
  )

  foreach ($base in $Candidates) {
    try {
      Invoke-RestMethod -Method Get -Uri ($base.TrimEnd("/") + $HealthPath) -TimeoutSec 3 | Out-Null
      return $base.TrimEnd("/")
    }
    catch {
    }
  }
  return $null
}

function Get-EnvValue {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(Mandatory = $true)][string]$Key
  )
  if (-not (Test-Path $FilePath)) { return $null }
  $line = Get-Content -Encoding UTF8 $FilePath | Where-Object { $_ -match "^\s*$Key\s*=" } | Select-Object -First 1
  if (-not $line) { return $null }
  return (($line -split "=", 2)[1]).Trim()
}

function Invoke-PromQuery {
  param(
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][string]$Query
  )
  $encoded = [System.Uri]::EscapeDataString($Query)
  $uri = "$BaseUrl/api/v1/query?query=$encoded"
  $res = Invoke-RestMethod -Method Get -Uri $uri -TimeoutSec 8
  if ($res.status -ne "success") { return $null }
  if (-not $res.data.result -or @($res.data.result).Count -eq 0) { return $null }
  return @($res.data.result)[0].value[1]
}

function To-DoubleOrNull {
  param([object]$Value)
  if ($null -eq $Value) { return $null }
  $out = 0.0
  if ([double]::TryParse([string]$Value, [ref]$out)) { return $out }
  return $null
}

function Get-RabbitBacklog {
  param(
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][string]$User,
    [Parameter(Mandatory = $true)][string]$Password
  )

  $pair = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${User}:${Password}"))
  $headers = @{ Authorization = "Basic $pair" }
  $queues = Invoke-RestMethod -Method Get -Uri ($BaseUrl + "/api/queues") -Headers $headers -TimeoutSec 8

  $ready = 0
  $unacked = 0
  foreach ($q in @($queues)) {
    $ready += [int]$q.messages_ready
    $unacked += [int]$q.messages_unacknowledged
  }
  return @{
    ready = $ready
    unacked = $unacked
    total = ($ready + $unacked)
  }
}

function Get-DbLockCounters {
  param(
    [Parameter(Mandatory = $true)][string]$ContainerName,
    [Parameter(Mandatory = $true)][string]$DbName,
    [Parameter(Mandatory = $true)][string]$SaPassword
  )

  $sql = @"
SET NOCOUNT ON;
SELECT
  SUM(CASE WHEN counter_name = 'Number of Deadlocks/sec' THEN cntr_value ELSE 0 END) AS deadlock_counter,
  SUM(CASE WHEN counter_name = 'Lock Timeouts/sec' THEN cntr_value ELSE 0 END) AS lock_timeout_counter
FROM sys.dm_os_performance_counters
WHERE object_name LIKE '%:Locks%'
  AND instance_name = '_Total'
  AND counter_name IN ('Number of Deadlocks/sec', 'Lock Timeouts/sec');
"@

  $result = docker exec $ContainerName /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P $SaPassword -C -d $DbName -W -s "," -h -1 -Q $sql

  if ($LASTEXITCODE -ne 0) {
    throw "sqlcmd query failed for container '$ContainerName'."
  }

  $line = ($result | Where-Object { $_ -match "^\s*\d+,\d+\s*$" } | Select-Object -First 1)
  if (-not $line) {
    throw "db lock counter row not found."
  }
  $parts = $line.Trim() -split ","
  return @{
    deadlock_counter = [int]$parts[0]
    lock_timeout_counter = [int]$parts[1]
  }
}

Push-Location $repoRoot
try {
  $evidenceDir = Join-Path $repoRoot $EvidenceRoot
  $runDir = Join-Path $evidenceDir $RunId
  New-Item -ItemType Directory -Force $runDir | Out-Null

  $selectedProm = $PrometheusBaseUrl
  if ([string]::IsNullOrWhiteSpace($selectedProm)) {
    $selectedProm = Select-Endpoint -Candidates @("http://localhost:19090", "http://localhost:9090") -HealthPath "/-/healthy"
  }
  if (-not $selectedProm) { throw "Prometheus endpoint not reachable." }

  $selectedRabbit = $RabbitApiBaseUrl
  if ([string]::IsNullOrWhiteSpace($selectedRabbit)) {
    foreach ($candidate in @("http://localhost:35672", "http://localhost:15672")) {
      $u = if ($candidate -like "*35672*") { "scm_stage" } else { "scm" }
      $p = if ($candidate -like "*35672*") { "scm_stage_1234" } else { "scm1234" }
      $pair = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${u}:${p}"))
      try {
        Invoke-RestMethod -Method Get -Uri ($candidate + "/api/overview") -Headers @{ Authorization = "Basic $pair" } -TimeoutSec 4 | Out-Null
        $selectedRabbit = $candidate
        if ([string]::IsNullOrWhiteSpace($RabbitUser)) { $RabbitUser = $u }
        if ([string]::IsNullOrWhiteSpace($RabbitPassword)) { $RabbitPassword = $p }
        break
      }
      catch {
      }
    }
  }
  if (-not $selectedRabbit) { throw "RabbitMQ management API endpoint not reachable." }

  if ([string]::IsNullOrWhiteSpace($RabbitUser)) {
    $RabbitUser = if ($selectedRabbit -like "*35672*") { "scm_stage" } else { "scm" }
  }
  if ([string]::IsNullOrWhiteSpace($RabbitPassword)) {
    $RabbitPassword = if ($selectedRabbit -like "*35672*") { "scm_stage_1234" } else { "scm1234" }
  }

  if ([string]::IsNullOrWhiteSpace($SqlContainerName)) {
    $SqlContainerName = if ($selectedRabbit -like "*35672*") { "scm-stg-sqlserver" } else { "scm-sqlserver" }
  }
  if ([string]::IsNullOrWhiteSpace($EnvFile)) {
    $EnvFile = if ($selectedRabbit -like "*35672*") { ".env.staging" } else { ".env" }
  }
  $saPassword = Get-EnvValue -FilePath (Join-Path $repoRoot $EnvFile) -Key "MSSQL_SA_PASSWORD"
  if ([string]::IsNullOrWhiteSpace($saPassword)) {
    throw "MSSQL_SA_PASSWORD not found in $EnvFile"
  }

  $q5xx = '(sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) or vector(0)) / clamp_min(sum(rate(http_server_requests_seconds_count[5m])), 1)'
  $qP95 = 'histogram_quantile(0.95, sum(rate(http_server_requests_seconds_bucket[5m])) by (le))'
  $qP99 = 'histogram_quantile(0.99, sum(rate(http_server_requests_seconds_bucket[5m])) by (le))'
  $qReq = 'sum(rate(http_server_requests_seconds_count[5m]))'
  $qSvc = 'sum(up{job="local-services"})'

  $metric5xx = To-DoubleOrNull (Invoke-PromQuery -BaseUrl $selectedProm -Query $q5xx)
  $metricP95 = To-DoubleOrNull (Invoke-PromQuery -BaseUrl $selectedProm -Query $qP95)
  $metricP99 = To-DoubleOrNull (Invoke-PromQuery -BaseUrl $selectedProm -Query $qP99)
  $metricReq = To-DoubleOrNull (Invoke-PromQuery -BaseUrl $selectedProm -Query $qReq)
  $metricSvc = To-DoubleOrNull (Invoke-PromQuery -BaseUrl $selectedProm -Query $qSvc)

  $rulesRes = Invoke-RestMethod -Method Get -Uri ($selectedProm + "/api/v1/rules") -TimeoutSec 8
  $ruleCount = 0
  foreach ($grp in @($rulesRes.data.groups)) {
    if ($grp.name -eq "scm-core-alerts") {
      $ruleCount += @($grp.rules).Count
    }
  }

  $rabbit = Get-RabbitBacklog -BaseUrl $selectedRabbit -User $RabbitUser -Password $RabbitPassword
  $db = Get-DbLockCounters -ContainerName $SqlContainerName -DbName $Database -SaPassword $saPassword

  $collectionMap = [ordered]@{
    error_rate_5xx = ($null -ne $metric5xx)
    p95_latency = ($null -ne $metricP95)
    p99_latency = ($null -ne $metricP99)
    request_rate = ($null -ne $metricReq)
    service_up_count = ($null -ne $metricSvc)
    rabbit_backlog = ($null -ne $rabbit)
    db_lock_counters = ($null -ne $db)
    alert_rules_loaded = ($ruleCount -ge 1)
  }

  $collected = (@($collectionMap.GetEnumerator() | Where-Object { $_.Value }).Count)
  $total = @($collectionMap.GetEnumerator()).Count
  $collectionPct = [Math]::Round(($collected * 100.0) / $total, 1)

  $threshold = [ordered]@{
    error_rate_5xx = 0.005
    p95_latency_sec = 0.35
    p99_latency_sec = 0.70
    rabbit_backlog_total = 1000
  }

  $thresholdPass = [ordered]@{
    error_rate_5xx = ($null -ne $metric5xx -and $metric5xx -le $threshold.error_rate_5xx)
    p95_latency_sec = ($null -ne $metricP95 -and $metricP95 -le $threshold.p95_latency_sec)
    p99_latency_sec = ($null -ne $metricP99 -and $metricP99 -le $threshold.p99_latency_sec)
    rabbit_backlog_total = ($null -ne $rabbit.total -and $rabbit.total -le $threshold.rabbit_backlog_total)
    db_deadlock_counter = ($db.deadlock_counter -eq 0)
  }

  $summary = [ordered]@{
    run_id = $RunId
    executed_at = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss K")
    endpoints = @{
      prometheus = $selectedProm
      rabbitmq_api = $selectedRabbit
      sql_container = $SqlContainerName
      env_file = $EnvFile
      database = $Database
    }
    metrics = @{
      error_rate_5xx = $metric5xx
      p95_latency_sec = $metricP95
      p99_latency_sec = $metricP99
      request_rate_rps = $metricReq
      service_up_count = $metricSvc
      rabbit_ready = $rabbit.ready
      rabbit_unacked = $rabbit.unacked
      rabbit_total = $rabbit.total
      db_deadlock_counter = $db.deadlock_counter
      db_lock_timeout_counter = $db.lock_timeout_counter
      scm_core_alert_rule_count = $ruleCount
    }
    collection = @{
      collected_items = $collected
      total_items = $total
      collected_percent = $collectionPct
      map = $collectionMap
    }
    threshold = $threshold
    threshold_pass = $thresholdPass
  }

  $jsonPath = Join-Path $runDir "scm234-observability-summary.json"
  $mdPath = Join-Path $runDir "scm234-observability-summary.md"
  $summary | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 $jsonPath

  $md = @()
  $md += "# SCM-234 Observability Summary"
  $md += ""
  $md += "- RunId: $RunId"
  $md += "- ExecutedAt: $($summary.executed_at)"
  $md += "- Prometheus: $selectedProm"
  $md += "- RabbitMQ API: $selectedRabbit"
  $md += "- SQL Container: $SqlContainerName"
  $md += ""
  $md += "## Metrics"
  $md += ""
  $md += "| Metric | Value |"
  $md += "|---|---:|"
  $md += "| 5xx error rate | $metric5xx |"
  $md += "| p95 latency (sec) | $metricP95 |"
  $md += "| p99 latency (sec) | $metricP99 |"
  $md += "| request rate (rps) | $metricReq |"
  $md += "| service up count | $metricSvc |"
  $md += "| rabbit ready | $($rabbit.ready) |"
  $md += "| rabbit unacked | $($rabbit.unacked) |"
  $md += "| rabbit total | $($rabbit.total) |"
  $md += "| db deadlock counter | $($db.deadlock_counter) |"
  $md += "| db lock timeout counter | $($db.lock_timeout_counter) |"
  $md += "| scm-core alert rule count | $ruleCount |"
  $md += ""
  $md += "## Collection Coverage"
  $md += ""
  $md += "- Collected: $collected / $total ($collectionPct%)"
  $md += ""
  $md += "## Threshold Check"
  $md += ""
  $md += "| Check | Threshold | Result |"
  $md += "|---|---:|---|"
  $md += "| 5xx error rate | <= 0.005 | $($thresholdPass.error_rate_5xx) |"
  $md += "| p95 latency | <= 0.35s | $($thresholdPass.p95_latency_sec) |"
  $md += "| p99 latency | <= 0.70s | $($thresholdPass.p99_latency_sec) |"
  $md += "| rabbit backlog total | <= 1000 | $($thresholdPass.rabbit_backlog_total) |"
  $md += "| db deadlock counter | == 0 | $($thresholdPass.db_deadlock_counter) |"
  $md += ""
  $md += "## Evidence Files"
  $md += ""
  $md += "- $jsonPath"
  $md += "- $mdPath"
  $md | Set-Content -Encoding UTF8 $mdPath

  Write-Host "[OK] observability summary generated:"
  Write-Host " - $mdPath"
  Write-Host " - $jsonPath"
  Write-Host ("[OK] metrics collection: {0}/{1} ({2}%)" -f $collected, $total, $collectionPct)

  if ($collectionPct -lt 100) {
    throw "[FAIL] metrics collection is incomplete."
  }

  if ($FailOnThreshold) {
    $allThresholdPass = @($thresholdPass.GetEnumerator() | Where-Object { $_.Value -eq $false }).Count -eq 0
    if (-not $allThresholdPass) {
      throw "[FAIL] one or more threshold checks failed."
    }
  }
}
finally {
  Pop-Location
}
