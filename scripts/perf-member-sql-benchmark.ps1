param(
  [string]$ContainerName = "scm-sqlserver",
  [string]$Database = "scm_rft",
  [string]$SaPassword = "",
  [string]$OutputDir = "doc/perf/reports",
  [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

function Get-EnvValue {
  param([string]$EnvFilePath, [string]$Key)
  if (-not (Test-Path $EnvFilePath)) { return $null }
  $line = Get-Content $EnvFilePath | Where-Object { $_ -match "^\s*$Key=" } | Select-Object -First 1
  if (-not $line) { return $null }
  return ($line -split "=", 2)[1].Trim()
}

if ([string]::IsNullOrWhiteSpace($SaPassword)) {
  $SaPassword = $env:MSSQL_SA_PASSWORD
}
if ([string]::IsNullOrWhiteSpace($SaPassword)) {
  $SaPassword = Get-EnvValue -EnvFilePath (Join-Path $RepoRoot ".env") -Key "MSSQL_SA_PASSWORD"
}
if ([string]::IsNullOrWhiteSpace($SaPassword)) {
  throw "MSSQL_SA_PASSWORD is required. Set env var or pass -SaPassword."
}

$resolvedOutputDir = if ([System.IO.Path]::IsPathRooted($OutputDir)) { $OutputDir } else { Join-Path $RepoRoot $OutputDir }
New-Item -ItemType Directory -Path $resolvedOutputDir -Force | Out-Null

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$sqlOutputPath = Join-Path $resolvedOutputDir ("member-sql-benchmark-{0}.log" -f $ts)

$benchmarkSql = @"
SET NOCOUNT ON;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SET STATISTICS XML ON;

DECLARE @size INT = 20;

PRINT 'SCENARIO: status-only-page0';
SELECT member_id, member_name, status
FROM dbo.members
WHERE status = N'ACTIVE'
ORDER BY member_id
OFFSET 0 ROWS FETCH NEXT @size ROWS ONLY;

PRINT 'SCENARIO: keyword-prefix-page0';
SELECT member_id, member_name, status
FROM dbo.members
WHERE member_id LIKE N'M0001%'
ORDER BY member_id
OFFSET 0 ROWS FETCH NEXT @size ROWS ONLY;

PRINT 'SCENARIO: status-keyword-page0';
SELECT member_id, member_name, status
FROM dbo.members
WHERE status = N'ACTIVE'
  AND member_name LIKE N'ALPHA%'
ORDER BY member_id
OFFSET 0 ROWS FETCH NEXT @size ROWS ONLY;

PRINT 'SCENARIO: status-only-page1000';
SELECT member_id, member_name, status
FROM dbo.members
WHERE status = N'ACTIVE'
ORDER BY member_id
OFFSET 20000 ROWS FETCH NEXT @size ROWS ONLY;

SET STATISTICS XML OFF;
"@

$tempFile = Join-Path $env:TEMP ("member-sql-benchmark-{0}.sql" -f [guid]::NewGuid().ToString("N"))
$benchmarkSql | Set-Content -Path $tempFile -Encoding UTF8

try {
  $remotePath = "/var/opt/mssql/member-sql-benchmark.sql"
  & docker cp $tempFile "$ContainerName`:$remotePath"
  if ($LASTEXITCODE -ne 0) {
    throw "docker cp failed."
  }

  $output = & docker exec $ContainerName /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $SaPassword -C -d $Database -W -w 4000 -b -i $remotePath
  if ($LASTEXITCODE -ne 0) {
    throw "sql benchmark failed."
  }

  $output | Set-Content -Path $sqlOutputPath -Encoding UTF8
  Write-Host ("[OK] SQL benchmark log created: {0}" -f $sqlOutputPath)
}
finally {
  if (Test-Path $tempFile) {
    Remove-Item -Force $tempFile
  }
  & docker exec $ContainerName rm -f /var/opt/mssql/member-sql-benchmark.sql 2>$null | Out-Null
}
