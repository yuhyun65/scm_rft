param(
  [string]$ConfigPath = "migration/verify/config.sample.json",
  [string]$OutputDir = "migration/reports",
  [switch]$FailOnMismatch
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$resolvedConfig = if ([System.IO.Path]::IsPathRooted($ConfigPath)) { $ConfigPath } else { Join-Path $repoRoot $ConfigPath }
$resolvedOutputDir = if ([System.IO.Path]::IsPathRooted($OutputDir)) { $OutputDir } else { Join-Path $repoRoot $OutputDir }

if (-not (Test-Path $resolvedConfig)) {
  throw "Validation config not found: $resolvedConfig"
}

New-Item -ItemType Directory -Force -Path $resolvedOutputDir | Out-Null
$cfg = Get-Content -Raw -Encoding UTF8 $resolvedConfig | ConvertFrom-Json

$results = @()
$failed = 0

function Add-Result {
  param(
    [string]$Type,
    [string]$Name,
    [string]$Expected,
    [string]$Actual,
    [bool]$Passed
  )

  if (-not $Passed) { $script:failed++ }
  $script:results += [pscustomobject]@{
    Type = $Type
    Name = $Name
    Expected = $Expected
    Actual = $Actual
    Passed = $Passed
  }
}

# count checks
foreach ($item in @($cfg.countChecks)) {
  $pass = ([decimal]$item.source -eq [decimal]$item.target)
  Add-Result -Type "count" -Name $item.name -Expected ([string]$item.source) -Actual ([string]$item.target) -Passed $pass
}

# sum checks
foreach ($item in @($cfg.sumChecks)) {
  $tol = 0.0
  if ($null -ne $item.tolerance) { $tol = [double]$item.tolerance }
  $delta = [math]::Abs(([double]$item.source) - ([double]$item.target))
  $pass = ($delta -le $tol)
  Add-Result -Type "sum" -Name $item.name -Expected ([string]$item.source) -Actual ("{0} (delta={1})" -f $item.target, $delta) -Passed $pass
}

# sample checks
foreach ($item in @($cfg.sampleChecks)) {
  $pass = ([string]$item.sourceValue -eq [string]$item.targetValue)
  Add-Result -Type "sample" -Name $item.name -Expected ([string]$item.sourceValue) -Actual ([string]$item.targetValue) -Passed $pass
}

# file existence checks
foreach ($item in @($cfg.fileExistenceChecks)) {
  $root = if ([System.IO.Path]::IsPathRooted([string]$item.rootPath)) { [string]$item.rootPath } else { Join-Path $repoRoot ([string]$item.rootPath) }
  foreach ($file in @($item.files)) {
    $filePath = Join-Path $root ([string]$file)
    $pass = Test-Path $filePath
    $actual = "missing"
    if ($pass) { $actual = "exists" }
    Add-Result -Type "file" -Name ("{0}:{1}" -f $item.name, $file) -Expected "exists" -Actual $actual -Passed $pass
  }
}

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$reportPath = Join-Path $resolvedOutputDir ("validation-{0}.md" -f $ts)

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# Migration Validation Report")
[void]$sb.AppendLine("")
[void]$sb.AppendLine(("- Config: {0}" -f $resolvedConfig))
[void]$sb.AppendLine(("- ExecutedAt: {0}" -f (Get-Date).ToString("s")))
[void]$sb.AppendLine(("- TotalChecks: {0}" -f $results.Count))
[void]$sb.AppendLine(("- FailedChecks: {0}" -f $failed))
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| type | name | expected | actual | passed |")
[void]$sb.AppendLine("|---|---|---|---|---|")
foreach ($r in $results) {
  [void]$sb.AppendLine(("| {0} | {1} | {2} | {3} | {4} |" -f $r.Type, $r.Name, $r.Expected, $r.Actual, $r.Passed))
}

$sb.ToString() | Set-Content -Encoding UTF8 $reportPath

Write-Host ("[INFO] Validation report: {0}" -f $reportPath)
if ($failed -gt 0) {
  Write-Host ("[WARN] Validation found {0} mismatch(es)." -f $failed)
  if ($FailOnMismatch) {
    exit 1
  }
}
else {
  Write-Host "[OK] All validation checks passed."
}
