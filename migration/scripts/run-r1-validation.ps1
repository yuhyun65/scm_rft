param(
  [string]$RunId = "",
  [string]$Server = "localhost,1433",
  [string]$Database = "master",
  [string]$User = "sa",
  [string]$Password = "",
  [string]$EnvFile = ".env.staging",
  [string]$SqlContainerName = "scm-stg-sqlserver",
  [string]$SqlDir = "migration/sql/r1-validation",
  [string]$ReportDir = "migration/reports",
  [switch]$UseTrustedConnection,
  [switch]$UseDockerSqlcmd,
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

if (-not $UseTrustedConnection -and [string]::IsNullOrWhiteSpace($Password)) {
  $envPath = Join-Path $repoRoot $EnvFile
  $Password = Get-EnvValue -FilePath $envPath -Key "MSSQL_SA_PASSWORD"
}

if (-not $UseTrustedConnection -and [string]::IsNullOrWhiteSpace($Password) -and -not $SkipSqlExecution) {
  throw "MSSQL_SA_PASSWORD is empty. set -Password or configure $EnvFile"
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
$executionMode = "none"

function Invoke-WithHostSqlcmd {
  param(
    [Parameter(Mandatory = $true)][string]$SqlPath,
    [Parameter(Mandatory = $true)][string]$OutPath
  )

  $args = @(
    "-S", $Server,
    "-d", $Database,
    "-i", $SqlPath,
    "-o", $OutPath,
    "-b",
    "-W",
    "-s", "|",
    "-h", "-1"
  )
  if ($UseTrustedConnection) {
    $args += "-E"
  }
  else {
    $args += @("-U", $User, "-P", $Password, "-C")
  }

  & sqlcmd @args
  if ($LASTEXITCODE -ne 0) {
    throw ("sqlcmd failed for {0}" -f (Split-Path $SqlPath -Leaf))
  }
}

function Invoke-WithDockerSqlcmd {
  param(
    [Parameter(Mandatory = $true)][string]$SqlPath,
    [Parameter(Mandatory = $true)][string]$OutPath
  )

  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "docker not found and sqlcmd not available on host."
  }

  $runningContainers = docker ps --format "{{.Names}}"
  if (($runningContainers | Where-Object { $_ -eq $SqlContainerName }).Count -eq 0) {
    throw "sqlcmd fallback container is not running: $SqlContainerName"
  }

  $uid = [System.Guid]::NewGuid().ToString("N")
  $tmpQuery = "/tmp/r1_$uid.sql"
  $tmpRaw = "/tmp/r1_$uid.out"

  & docker cp $SqlPath "$SqlContainerName`:$tmpQuery"
  if ($LASTEXITCODE -ne 0) {
    throw "docker cp query failed: $SqlPath"
  }

  try {
    $args = @(
      "exec", $SqlContainerName,
      "/opt/mssql-tools18/bin/sqlcmd",
      "-S", "localhost",
      "-U", $User,
      "-P", $Password,
      "-C",
      "-d", $Database,
      "-i", $tmpQuery,
      "-b",
      "-W",
      "-s", "|",
      "-h", "-1",
      "-o", $tmpRaw
    )

    & docker @args
    if ($LASTEXITCODE -ne 0) {
      throw "docker sqlcmd execution failed."
    }

    & docker cp "$SqlContainerName`:$tmpRaw" $OutPath
    if ($LASTEXITCODE -ne 0) {
      throw "docker cp output failed."
    }
  }
  finally {
    & docker exec --user 0 $SqlContainerName /bin/sh -c "rm -f $tmpQuery $tmpRaw >/dev/null 2>&1 || true" | Out-Null
  }
}

function Invoke-ValidationSql {
  param(
    [Parameter(Mandatory = $true)][string]$SqlPath,
    [Parameter(Mandatory = $true)][string]$OutPath
  )

  $hasHostSqlcmd = $null -ne (Get-Command sqlcmd -ErrorAction SilentlyContinue)

  if ($UseDockerSqlcmd) {
    Invoke-WithDockerSqlcmd -SqlPath $SqlPath -OutPath $OutPath
    return "docker-sqlcmd"
  }

  if ($hasHostSqlcmd) {
    Invoke-WithHostSqlcmd -SqlPath $SqlPath -OutPath $OutPath
    return "host-sqlcmd"
  }

  try {
    Invoke-WithDockerSqlcmd -SqlPath $SqlPath -OutPath $OutPath
    return "docker-sqlcmd"
  }
  catch {
    $invokeSqlcmd = Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue
    if (-not $invokeSqlcmd) {
      Import-Module SqlServer -ErrorAction SilentlyContinue
      $invokeSqlcmd = Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue
    }
    if (-not $invokeSqlcmd) {
      throw "Neither sqlcmd nor docker sqlcmd nor Invoke-Sqlcmd is available."
    }

    $conn = if ($UseTrustedConnection) {
      "Server=$Server;Database=$Database;Trusted_Connection=True;TrustServerCertificate=True;Encrypt=False;"
    }
    else {
      "Server=$Server;Database=$Database;User ID=$User;Password=$Password;TrustServerCertificate=True;Encrypt=False;"
    }

    $result = Invoke-Sqlcmd -ConnectionString $conn -InputFile $SqlPath -QueryTimeout 600 -ErrorAction Stop
    if ($null -eq $result) {
      "" | Set-Content -Path $OutPath -Encoding UTF8
    }
    else {
      $result | ConvertTo-Csv -NoTypeInformation | Set-Content -Path $OutPath -Encoding UTF8
    }
    return "invoke-sqlcmd"
  }
}

if (-not $SkipSqlExecution) {
  foreach ($item in $domains) {
    $sqlPath = Join-Path $resolvedSqlDir $item.File
    if (-not (Test-Path $sqlPath)) {
      throw "SQL file not found: $sqlPath"
    }

    $outPath = Join-Path $resolvedReportDir ("R1-{0}-{1}.out.txt" -f $RunId, $item.Key)
    Write-Host ("[INFO] executing: {0}" -f $item.File)
    $mode = Invoke-ValidationSql -SqlPath $sqlPath -OutPath $outPath
    if ($executionMode -eq "none") {
      $executionMode = $mode
      Write-Host ("[INFO] validation SQL mode: {0}" -f $executionMode)
    }

    $outputs += [pscustomobject]@{
      Domain = $item.Key
      OutputPath = $outPath
    }
  }
}
else {
  $executionMode = "skipped"
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
[void]$sb.AppendLine(("- SqlMode: {0}" -f $executionMode))
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Domain Execution Order")
[void]$sb.AppendLine("auth -> member -> file -> inventory -> report -> order-lot -> board -> quality-doc")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Raw Outputs")
[void]$sb.AppendLine("| Domain | Output File |")
[void]$sb.AppendLine("|---|---|")
if ($outputs.Count -eq 0) {
  foreach ($item in $domains) {
    [void]$sb.AppendLine(("| {0} | PENDING (R1-{1}-{0}.out.txt) |" -f $item.Key, $RunId))
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
