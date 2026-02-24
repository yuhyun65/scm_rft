param(
  [string]$Database = "MES_HI",
  [string]$ContainerName = "scm-sqlserver",
  [string]$EnvFile = ".env",
  [switch]$Staging,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")

function Get-EnvValue {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(Mandatory = $true)][string]$Key
  )

  if (-not (Test-Path $FilePath)) {
    return $null
  }

  $line = Get-Content -Encoding UTF8 $FilePath | Where-Object { $_ -match "^\s*$Key\s*=" } | Select-Object -First 1
  if (-not $line) {
    return $null
  }

  return (($line -split "=", 2)[1]).Trim()
}

Push-Location $root
try {
  if ($Staging) {
    if ([string]::IsNullOrWhiteSpace($ContainerName) -or $ContainerName -eq "scm-sqlserver") {
      $ContainerName = "scm-stg-sqlserver"
    }
    if ($EnvFile -eq ".env") {
      $EnvFile = ".env.staging"
    }
  }

  $backupRoot = Join-Path $root "migration/backups"
  if ($Staging) {
    $backupRoot = Join-Path $backupRoot "staging"
  }
  New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

  $password = Get-EnvValue -FilePath (Join-Path $root $EnvFile) -Key "MSSQL_SA_PASSWORD"
  if ([string]::IsNullOrWhiteSpace($password)) {
    throw "MSSQL_SA_PASSWORD not found in $EnvFile"
  }

  $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $backupFile = "$($Database)_$timestamp.bak"
  $containerBackupPath = "/var/opt/mssql/backup/$backupFile"

  $sql = "BACKUP DATABASE [$Database] TO DISK = N'$containerBackupPath' WITH INIT, COMPRESSION, CHECKSUM, STATS = 5;"
  $cmd = @(
    "exec", $ContainerName,
    "/opt/mssql-tools18/bin/sqlcmd",
    "-S", "localhost",
    "-U", "sa",
    "-P", $password,
    "-C",
    "-Q", $sql
  )

  if ($DryRun) {
    Write-Host "[DRYRUN] docker $($cmd -join ' ')"
    return
  }

  & docker @cmd
  if ($LASTEXITCODE -ne 0) {
    throw "Database backup failed."
  }

  Write-Host "[OK] Backup completed."
  Write-Host "Container: $ContainerName"
  Write-Host "Database : $Database"
  Write-Host "File     : $backupFile"
  Write-Host "HostDir  : $backupRoot"
}
finally {
  Pop-Location
}
