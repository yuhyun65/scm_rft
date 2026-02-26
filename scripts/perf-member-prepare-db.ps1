param(
  [string]$ContainerName = "scm-sqlserver",
  [string]$Database = "scm_rft",
  [string]$SaPassword = "",
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

function Invoke-ContainerSqlcmd {
  param(
    [string]$Container,
    [string]$Password,
    [string]$Db,
    [string]$Query
  )
  & docker exec $Container /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $Password -C -d $Db -b -Q $Query
  if ($LASTEXITCODE -ne 0) {
    throw "sqlcmd query failed."
  }
}

cmd /c "docker info >nul 2>nul"
if ($LASTEXITCODE -ne 0) {
  throw "Docker daemon is not running."
}

 $runningNames = (& docker ps --format "{{.Names}}")
if ($LASTEXITCODE -ne 0) {
  throw "Failed to read docker container status."
}
if (-not ($runningNames -contains $ContainerName)) {
  throw "Container '$ContainerName' is not running. Run scripts/dev-up.ps1 first."
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

Write-Host "[INFO] Ensure database exists: $Database"
Invoke-ContainerSqlcmd -Container $ContainerName -Password $SaPassword -Db "master" -Query "IF DB_ID(N'$Database') IS NULL CREATE DATABASE [$Database];"

$migrationFiles = @(
  "V1__baseline.sql",
  "V2__core_domains.sql",
  "V3__auth_member_lookup_indexes.sql",
  "V4__auth_credentials.sql",
  "V5__member_search_tuning_indexes.sql"
)

foreach ($file in $migrationFiles) {
  $localPath = Join-Path $RepoRoot ("migration/flyway/{0}" -f $file)
  if (-not (Test-Path $localPath)) {
    throw "Migration file not found: $localPath"
  }

  $remotePath = "/var/opt/mssql/$file"
  Write-Host "[INFO] Apply migration: $file"
  & docker cp $localPath "$ContainerName`:$remotePath"
  if ($LASTEXITCODE -ne 0) {
    throw "docker cp failed for $file"
  }

  & docker exec $ContainerName /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $SaPassword -C -d $Database -b -i $remotePath
  if ($LASTEXITCODE -ne 0) {
    throw "Migration apply failed: $file"
  }

  & docker exec $ContainerName rm -f $remotePath 2>$null | Out-Null
}

Write-Host "[OK] Database and migrations are ready."
