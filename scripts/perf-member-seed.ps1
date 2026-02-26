param(
  [int]$RowCount = 100000,
  [string]$ContainerName = "scm-sqlserver",
  [string]$Database = "scm_rft",
  [string]$SaPassword = "",
  [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

if ($RowCount -lt 1) {
  throw "RowCount must be greater than 0."
}

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

$seedSql = @"
SET NOCOUNT ON;

DELETE FROM dbo.auth_credentials;
DELETE FROM dbo.members;

;WITH nums AS (
    SELECT TOP ($RowCount)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.members (member_id, member_name, status, created_at, updated_at)
SELECT
    CONCAT('M', RIGHT(REPLICATE('0', 7) + CAST(n AS VARCHAR(7)), 7)) AS member_id,
    CONCAT(
        CHOOSE((n % 10) + 1, 'ALPHA', 'BETA', 'GAMMA', 'DELTA', 'OMEGA', 'NOVA', 'CORE', 'TRUST', 'MATE', 'PRIME'),
        '-',
        RIGHT(REPLICATE('0', 6) + CAST(n AS VARCHAR(6)), 6)
    ) AS member_name,
    CASE WHEN n % 10 < 8 THEN 'ACTIVE' ELSE 'INACTIVE' END AS status,
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM nums;

UPDATE STATISTICS dbo.members WITH FULLSCAN;
"@

$tempFile = Join-Path $env:TEMP ("member-seed-{0}.sql" -f [guid]::NewGuid().ToString("N"))
$seedSql | Set-Content -Path $tempFile -Encoding UTF8

try {
  $remotePath = "/var/opt/mssql/member-seed.sql"
  & docker cp $tempFile "$ContainerName`:$remotePath"
  if ($LASTEXITCODE -ne 0) {
    throw "docker cp failed."
  }

  $start = Get-Date
  & docker exec $ContainerName /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $SaPassword -C -d $Database -b -i $remotePath
  if ($LASTEXITCODE -ne 0) {
    throw "member seed sql failed."
  }
  $elapsed = (Get-Date) - $start
  Write-Host ("[OK] Seed completed. rows={0}, elapsed={1:n1}s" -f $RowCount, $elapsed.TotalSeconds)
}
finally {
  if (Test-Path $tempFile) {
    Remove-Item -Force $tempFile
  }
  & docker exec $ContainerName rm -f /var/opt/mssql/member-seed.sql 2>$null | Out-Null
}
