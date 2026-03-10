param(
  [string]$RunId = ("SCM-236-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")),
  [string]$Server = "localhost,1433",
  [string]$TargetDatabase = "MES_HI",
  [string]$User = "sa",
  [string]$Password = "",
  [string]$EnvFile = ".env.staging",
  [string]$SqlContainerName = "scm-stg-sqlserver",
  [string]$ReportDir = "migration/reports",
  [double]$SumDeltaThresholdPct = 0.1,
  [double]$StatusDeltaThresholdPp = 1.0,
  [switch]$UseTrustedConnection,
  [switch]$UseDockerSqlcmd,
  [switch]$SkipDryRun,
  [switch]$SkipR1Sql,
  [switch]$FailOnMismatch
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$resolvedReportDir = if ([System.IO.Path]::IsPathRooted($ReportDir)) { $ReportDir } else { Join-Path $repoRoot $ReportDir }
$evidenceDir = Join-Path $repoRoot ("runbooks/evidence/{0}" -f $RunId)
New-Item -ItemType Directory -Force -Path $resolvedReportDir | Out-Null
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null

$domains = @("auth", "member", "file", "inventory", "report", "order-lot", "board", "quality-doc")

function Invoke-LoggedCommand {
  param(
    [Parameter(Mandatory = $true)][scriptblock]$Action,
    [Parameter(Mandatory = $true)][string]$LogPath,
    [Parameter(Mandatory = $true)][string]$StepName
  )

  Write-Host ("[INFO] step start: {0}" -f $StepName)
  & $Action 2>&1 | Tee-Object -FilePath $LogPath | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw ("[FAIL] step failed: {0}" -f $StepName)
  }
  if (Select-String -Path $LogPath -SimpleMatch "[FAIL]" -Quiet) {
    throw ("[FAIL] step log contains [FAIL]: {0}" -f $StepName)
  }
  Write-Host ("[OK] step complete: {0}" -f $StepName)
}

function Is-Number {
  param([string]$Value)
  $out = 0.0
  return [double]::TryParse($Value, [ref]$out)
}

function Is-Integer {
  param([string]$Value)
  $out = 0
  return [long]::TryParse($Value, [ref]$out)
}

function Parse-DomainMetrics {
  param(
    [Parameter(Mandatory = $true)][string]$Domain,
    [Parameter(Mandatory = $true)][string]$FilePath
  )

  $countMismatch = $null
  $sumDelta = $null
  $sampleMismatch = $null
  $statusDelta = $null

  if (-not (Test-Path $FilePath)) {
    return [pscustomobject]@{
      domain = $Domain
      count_mismatch = $null
      sum_delta_pct = $null
      sample_mismatch = $null
      status_delta_pp = $null
      verdict = "MISSING"
    }
  }

  $lines = Get-Content -Encoding UTF8 $FilePath | Where-Object {
    -not [string]::IsNullOrWhiteSpace($_) -and $_.Contains("|")
  }

  foreach ($line in $lines) {
    $tokens = @($line.Split("|") | ForEach-Object { $_.Trim() })
    if ($tokens.Count -lt 2) { continue }
    if ($tokens[0] -ne $Domain) { continue }

    switch ($tokens.Count) {
      3 {
        if ((Is-Integer $tokens[1]) -and (Is-Integer $tokens[2])) {
          $val = [long]$tokens[2]
          if ($null -eq $sampleMismatch -or $val -gt $sampleMismatch) { $sampleMismatch = $val }
        }
      }
      4 {
        if ((Is-Integer $tokens[1]) -and (Is-Integer $tokens[2]) -and (Is-Integer $tokens[3])) {
          $val = [long]$tokens[3]
          if ($null -eq $countMismatch -or $val -gt $countMismatch) { $countMismatch = $val }
        }
      }
      5 {
        if ((Is-Number $tokens[1]) -and (Is-Number $tokens[2]) -and (Is-Number $tokens[3]) -and (Is-Number $tokens[4])) {
          $val = [double]$tokens[4]
          if ($null -eq $sumDelta -or $val -gt $sumDelta) { $sumDelta = $val }
        }
        elseif ((Is-Integer $tokens[2]) -and (Is-Integer $tokens[3]) -and (Is-Integer $tokens[4])) {
          $val = [long]$tokens[4]
          if ($null -eq $countMismatch -or $val -gt $countMismatch) { $countMismatch = $val }
        }
      }
      6 {
        if ((Is-Number $tokens[2]) -and (Is-Number $tokens[3]) -and (Is-Number $tokens[4]) -and (Is-Number $tokens[5])) {
          $val = [double]$tokens[5]
          if ($null -eq $sumDelta -or $val -gt $sumDelta) { $sumDelta = $val }
        }
      }
      7 {
        if (Is-Number $tokens[6]) {
          $val = [double]$tokens[6]
          if ($null -eq $statusDelta -or $val -gt $statusDelta) { $statusDelta = $val }
        }
      }
    }
  }

  $verdict = "UNKNOWN"
  if (($null -ne $countMismatch) -and ($null -ne $sumDelta) -and ($null -ne $sampleMismatch) -and ($null -ne $statusDelta)) {
    $pass = ($countMismatch -eq 0) -and ($sumDelta -le $SumDeltaThresholdPct) -and ($sampleMismatch -eq 0) -and ($statusDelta -le $StatusDeltaThresholdPp)
    $verdict = $(if ($pass) { "PASS" } else { "FAIL" })
  }

  return [pscustomobject]@{
    domain = $Domain
    count_mismatch = $countMismatch
    sum_delta_pct = $sumDelta
    sample_mismatch = $sampleMismatch
    status_delta_pp = $statusDelta
    verdict = $verdict
  }
}

$dryRunLog = Join-Path $evidenceDir "dry-run.log"
$r1Log = Join-Path $evidenceDir "r1-validation.log"

if (-not $SkipDryRun) {
  Invoke-LoggedCommand -StepName "migration-dry-run" -LogPath $dryRunLog -Action {
    if ($FailOnMismatch) {
      & powershell -ExecutionPolicy Bypass -File (Join-Path $repoRoot "migration/scripts/dry-run.ps1") -RunId ("dryrun-{0}" -f $RunId) -OutputDir $ReportDir -FailOnMismatch
    }
    else {
      & powershell -ExecutionPolicy Bypass -File (Join-Path $repoRoot "migration/scripts/dry-run.ps1") -RunId ("dryrun-{0}" -f $RunId) -OutputDir $ReportDir
    }
  }
}
else {
  "[INFO] migration-dry-run skipped by option." | Set-Content -Path $dryRunLog -Encoding UTF8
}

$r1Args = @(
  "-ExecutionPolicy", "Bypass",
  "-File", (Join-Path $repoRoot "migration/scripts/run-r1-validation.ps1"),
  "-RunId", $RunId,
  "-Server", $Server,
  "-Database", $TargetDatabase,
  "-User", $User,
  "-EnvFile", $EnvFile,
  "-SqlContainerName", $SqlContainerName,
  "-ReportDir", $ReportDir
)

if (-not [string]::IsNullOrWhiteSpace($Password)) { $r1Args += @("-Password", $Password) }
if ($UseTrustedConnection) { $r1Args += "-UseTrustedConnection" }
if ($UseDockerSqlcmd) { $r1Args += "-UseDockerSqlcmd" }
if ($SkipR1Sql) { $r1Args += "-SkipSqlExecution" }

Invoke-LoggedCommand -StepName "r1-validation" -LogPath $r1Log -Action {
  & powershell @r1Args
}

$results = @()
foreach ($domain in $domains) {
  $outPath = Join-Path $resolvedReportDir ("R1-{0}-{1}.out.txt" -f $RunId, $domain)
  $results += Parse-DomainMetrics -Domain $domain -FilePath $outPath
}

$passCount = (@($results | Where-Object { $_.verdict -eq "PASS" })).Count
$failCount = (@($results | Where-Object { $_.verdict -eq "FAIL" })).Count
$unknownCount = (@($results | Where-Object { $_.verdict -eq "UNKNOWN" -or $_.verdict -eq "MISSING" })).Count
$finalVerdict = if ($failCount -eq 0 -and $unknownCount -eq 0) { "GO" } else { "NO-GO" }

$measuredMdPath = Join-Path $resolvedReportDir ("{0}-measured.md" -f $RunId)
$measuredJsonPath = Join-Path $resolvedReportDir ("{0}-measured.json" -f $RunId)

$md = New-Object System.Text.StringBuilder
[void]$md.AppendLine(("# {0} Measured Validation Report" -f $RunId))
[void]$md.AppendLine("")
[void]$md.AppendLine(("- GeneratedAt: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")))
[void]$md.AppendLine(("- Server: {0}" -f $Server))
[void]$md.AppendLine(("- TargetDB: {0}" -f $TargetDatabase))
[void]$md.AppendLine(("- Threshold: count=0, sum<={0}%, sample=0/200, status<={1}%p" -f $SumDeltaThresholdPct, $StatusDeltaThresholdPp))
[void]$md.AppendLine("")
[void]$md.AppendLine("## Summary")
[void]$md.AppendLine(("- DomainPass: {0}/{1}" -f $passCount, $domains.Count))
[void]$md.AppendLine(("- DomainFail: {0}" -f $failCount))
[void]$md.AppendLine(("- DomainUnknown: {0}" -f $unknownCount))
[void]$md.AppendLine(("- FinalVerdict: {0}" -f $finalVerdict))
[void]$md.AppendLine("")
[void]$md.AppendLine("## Domain Results")
[void]$md.AppendLine("| domain | count_mismatch | sum_delta_pct | sample_mismatch | status_delta_pp | verdict |")
[void]$md.AppendLine("|---|---:|---:|---:|---:|---|")
foreach ($r in $results) {
  [void]$md.AppendLine(("| {0} | {1} | {2} | {3} | {4} | {5} |" -f $r.domain, $r.count_mismatch, $r.sum_delta_pct, $r.sample_mismatch, $r.status_delta_pp, $r.verdict))
}

$md.ToString() | Set-Content -Path $measuredMdPath -Encoding UTF8

$jsonObj = [ordered]@{
  runId = $RunId
  generatedAt = (Get-Date).ToString("o")
  thresholds = [ordered]@{
    countMismatch = 0
    sumDeltaPct = $SumDeltaThresholdPct
    sampleMismatch = 0
    statusDeltaPp = $StatusDeltaThresholdPp
  }
  summary = [ordered]@{
    domainPass = $passCount
    domainFail = $failCount
    domainUnknown = $unknownCount
    finalVerdict = $finalVerdict
  }
  domains = $results
  logs = [ordered]@{
    dryRun = $dryRunLog
    r1Validation = $r1Log
  }
}
$jsonObj | ConvertTo-Json -Depth 8 | Set-Content -Path $measuredJsonPath -Encoding UTF8

$evidenceSummary = Join-Path $evidenceDir "scm236-cutover-summary.md"
@"
# SCM-236 Cutover Migration Automation Summary

- RunId: $RunId
- FinalVerdict: $finalVerdict
- DomainPass: $passCount/$($domains.Count)
- DomainUnknown: $unknownCount

## Artifacts
- $measuredMdPath
- $measuredJsonPath
- $dryRunLog
- $r1Log
"@ | Set-Content -Path $evidenceSummary -Encoding UTF8

Write-Host ("[OK] measured report: {0}" -f $measuredMdPath)
Write-Host ("[OK] measured json: {0}" -f $measuredJsonPath)
Write-Host ("[OK] evidence summary: {0}" -f $evidenceSummary)

if ($FailOnMismatch -and $finalVerdict -ne "GO") {
  throw "[FAIL] SCM-236 threshold check failed. finalVerdict=$finalVerdict"
}

