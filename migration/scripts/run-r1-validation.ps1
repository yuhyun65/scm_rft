param(
  [string]$RunId = "",
  [string]$Server = "localhost,1433",
  [string]$Database = "master",
  [string]$User = "sa",
  [string]$Password = "",
  [string]$SqlDir = "migration/sql/r1-validation",
  [string]$ReportDir = "migration/reports",
  [switch]$UseTrustedConnection,
  [switch]$SkipSqlExecution
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

if ([string]::IsNullOrWhiteSpace($RunId)) {
  $RunId = "R1-{0}-DEV" -f (Get-Date -Format "yyyyMMdd-HHmmss")
}

$resolvedSqlDir = if ([System.IO.Path]::IsPathRooted($SqlDir)) { $SqlDir } else { Join-Path $repoRoot $SqlDir }
$resolvedReportDir = if ([System.IO.Path]::IsPathRooted($ReportDir)) { $ReportDir } else { Join-Path $repoRoot $ReportDir }
$templatePath = Join-Path $resolvedReportDir "R1-report-template.md"

if (-not (Test-Path $resolvedSqlDir)) {
  throw "SQL directory not found: $resolvedSqlDir"
}
if (-not (Test-Path $templatePath)) {
  throw "Template not found: $templatePath"
}

New-Item -ItemType Directory -Force -Path $resolvedReportDir | Out-Null

$domains = @(
  @{ Key = "auth"; File = "01-auth-validation.sql" },
  @{ Key = "member"; File = "02-member-validation.sql" },
  @{ Key = "file"; File = "03-file-validation.sql" },
  @{ Key = "inventory"; File = "04-inventory-validation.sql" },
  @{ Key = "report"; File = "05-report-validation.sql" },
  @{ Key = "order-lot"; File = "06-order-lot-validation.sql" },
  @{ Key = "board"; File = "07-board-validation.sql" },
  @{ Key = "quality-doc"; File = "08-quality-doc-validation.sql" }
)

$outputs = @()

if (-not $SkipSqlExecution) {
  $sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
  if (-not $sqlcmd) {
    throw "sqlcmd is required. Install SQL Server command line tools or run with -SkipSqlExecution."
  }

  foreach ($item in $domains) {
    $sqlPath = Join-Path $resolvedSqlDir $item.File
    if (-not (Test-Path $sqlPath)) {
      throw "SQL file not found: $sqlPath"
    }

    $outPath = Join-Path $resolvedReportDir ("R1-{0}-{1}.out.txt" -f $RunId, $item.Key)
    $args = @("-S", $Server, "-d", $Database, "-i", $sqlPath, "-o", $outPath, "-b", "-I")
    if ($UseTrustedConnection) {
      $args += "-E"
    }
    else {
      if ([string]::IsNullOrWhiteSpace($Password)) {
        throw "Password is required when -UseTrustedConnection is not set."
      }
      $args += @("-U", $User, "-P", $Password)
    }

    Write-Host ("[INFO] executing: {0}" -f $item.File)
    & sqlcmd @args
    if ($LASTEXITCODE -ne 0) {
      throw ("sqlcmd failed for {0}" -f $item.File)
    }
    $outputs += [pscustomobject]@{
      Domain = $item.Key
      OutputPath = $outPath
    }
  }
}

$reportFile = Join-Path $resolvedReportDir ("{0}-execution.md" -f $RunId)
$template = Get-Content -Raw -Encoding UTF8 $templatePath
$template = $template.Replace("<R1-YYYYMMDD-HHMMSS-ENV>", $RunId)
$template = $template.Replace("<yyyy-MM-dd HH:mm:ss>", (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$template = $template.Replace("<DEV|STG|PRD-REHEARSAL>", "DEV")

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# SCM-213 R1 Execution Result")
[void]$sb.AppendLine("")
[void]$sb.AppendLine(("- RunId: {0}" -f $RunId))
[void]$sb.AppendLine(("- GeneratedAt: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")))
[void]$sb.AppendLine(("- SqlDir: {0}" -f $resolvedSqlDir))
[void]$sb.AppendLine(("- SqlExecution: {0}" -f ($(if ($SkipSqlExecution) { "SKIPPED" } else { "EXECUTED" }))))
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Domain Execution Order")
[void]$sb.AppendLine("auth -> member -> file -> inventory -> report -> order-lot -> board -> quality-doc")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Raw Outputs")
[void]$sb.AppendLine("| Domain | Output File |")
[void]$sb.AppendLine("|---|---|")
if ($outputs.Count -eq 0) {
  foreach ($item in $domains) {
    [void]$sb.AppendLine(("| {0} | PENDING ({1}-{0}.out.txt) |" -f $item.Key, $RunId))
  }
}
else {
  foreach ($out in $outputs) {
    $relative = $out.OutputPath.Replace($repoRoot + "\", "")
    [void]$sb.AppendLine(("| {0} | {1} |" -f $out.Domain, $relative))
  }
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## R1 Thresholds")
[void]$sb.AppendLine("- count mismatch = 0")
[void]$sb.AppendLine("- sum delta <= 0.1%")
[void]$sb.AppendLine("- sample mismatch = 0/200")
[void]$sb.AppendLine("- status delta <= 1.0%p")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Template Appendix")
[void]$sb.AppendLine("")
[void]$sb.AppendLine($template)

$sb.ToString() | Set-Content -Encoding UTF8 $reportFile
Write-Host ("[OK] R1 execution report created: {0}" -f $reportFile)
