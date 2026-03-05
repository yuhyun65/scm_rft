param(
  [string]$RunId = "",
  [string]$Server = "localhost,11433",
  [string]$Database = "MES_HI",
  [string]$User = "sa",
  [string]$Password = "",
  [string]$EnvFile = ".env.staging",
  [string]$OutputRoot = "migration/reverse",
  [string]$SqlDir = "sql/reverse",
  [string]$SqlContainerName = "scm-stg-sqlserver",
  [switch]$UseTrustedConnection
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

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

if ([string]::IsNullOrWhiteSpace($RunId)) {
  $RunId = "DB-RE-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
}

if (-not $UseTrustedConnection -and [string]::IsNullOrWhiteSpace($Password)) {
  $envPath = Join-Path $repoRoot $EnvFile
  $Password = Get-EnvValue -FilePath $envPath -Key "MSSQL_SA_PASSWORD"
}

if (-not $UseTrustedConnection -and [string]::IsNullOrWhiteSpace($Password)) {
  throw "MSSQL_SA_PASSWORD is empty. set -Password or configure $EnvFile"
}

$querySpecs = @(
  @{
    File = "01_tables_columns.sql"
    Csv = "01_tables_columns.csv"
    Header = "table_schema,table_name,column_id,column_name,system_type,data_type_display,max_length,precision,scale,is_nullable,is_identity,is_computed,default_definition,collation_name"
  },
  @{
    File = "02_pk_uk_fk.sql"
    Csv = "02_pk_uk_fk.csv"
    Header = "relation_type,constraint_name,parent_schema,parent_table,parent_columns,referenced_schema,referenced_table,referenced_columns,delete_action,update_action,is_disabled,is_not_trusted"
  },
  @{
    File = "03_indexes.sql"
    Csv = "03_indexes.csv"
    Header = "table_schema,table_name,index_name,index_type,is_unique,is_primary_key,is_unique_constraint,fill_factor,has_filter,filter_definition,key_columns,included_columns"
  },
  @{
    File = "04_constraints.sql"
    Csv = "04_constraints.csv"
    Header = "constraint_type,constraint_name,table_schema,table_name,column_name,definition,is_disabled,is_not_trusted"
  },
  @{
    File = "05_sp_dependencies.sql"
    Csv = "05_sp_dependencies.csv"
    Header = "procedure_schema,procedure_name,referenced_schema,referenced_entity,referenced_type_desc,referenced_class_desc,is_ambiguous,is_caller_dependent"
  },
  @{
    File = "06_rowcount.sql"
    Csv = "06_rowcount.csv"
    Header = "table_schema,table_name,row_count"
  }
)

$outDir = Join-Path $repoRoot (Join-Path $OutputRoot $RunId)
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Export-WithHostSqlcmd {
  param(
    [Parameter(Mandatory = $true)][string]$QueryPath,
    [Parameter(Mandatory = $true)][string]$RawOutputPath
  )

  $args = @(
    "-S", $Server,
    "-d", $Database,
    "-i", $QueryPath,
    "-W",
    "-s", ",",
    "-h", "-1",
    "-o", $RawOutputPath
  )

  if ($UseTrustedConnection) {
    $args += "-E"
  }
  else {
    $args += @("-U", $User, "-P", $Password, "-C")
  }

  & sqlcmd @args
  if ($LASTEXITCODE -ne 0) {
    throw "sqlcmd failed for query path: $QueryPath"
  }
}

function Export-WithDockerSqlcmd {
  param(
    [Parameter(Mandatory = $true)][string]$QueryPath,
    [Parameter(Mandatory = $true)][string]$RawOutputPath
  )

  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "docker not found and sqlcmd not available on host."
  }

  $runningContainers = docker ps --format "{{.Names}}"
  if (($runningContainers | Where-Object { $_ -eq $SqlContainerName }).Count -eq 0) {
    throw "sqlcmd fallback container is not running: $SqlContainerName"
  }

  $uid = [System.Guid]::NewGuid().ToString("N")
  $tmpQuery = "/tmp/reverse_$uid.sql"
  $tmpRaw = "/tmp/reverse_$uid.csv"

  & docker cp $QueryPath "$SqlContainerName`:$tmpQuery"
  if ($LASTEXITCODE -ne 0) {
    throw "docker cp query failed: $QueryPath"
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
      "-W",
      "-s", ",",
      "-h", "-1",
      "-o", $tmpRaw
    )

    & docker @args
    if ($LASTEXITCODE -ne 0) {
      throw "docker sqlcmd execution failed."
    }

    & docker cp "$SqlContainerName`:$tmpRaw" $RawOutputPath
    if ($LASTEXITCODE -ne 0) {
      throw "docker cp output failed."
    }
  }
  finally {
    # docker cp creates root-owned temp files in container; cleanup as root to avoid noisy permission warnings.
    & docker exec --user 0 $SqlContainerName /bin/sh -c "rm -f $tmpQuery $tmpRaw >/dev/null 2>&1 || true" | Out-Null
  }
}

$useHostSqlcmd = $null -ne (Get-Command sqlcmd -ErrorAction SilentlyContinue)
if ($useHostSqlcmd) {
  Write-Host "[INFO] export mode: host-sqlcmd"
}
else {
  Write-Host ("[INFO] export mode: docker-sqlcmd (container={0})" -f $SqlContainerName)
}

foreach ($spec in $querySpecs) {
  $queryFile = $spec.File
  $queryPath = Join-Path $repoRoot (Join-Path $SqlDir $queryFile)
  if (-not (Test-Path $queryPath)) {
    throw "query file not found: $queryPath"
  }

  $csvPath = Join-Path $outDir $spec.Csv
  $rawPath = Join-Path $outDir ("raw-" + $spec.Csv)

  Write-Host ("[INFO] exporting {0} -> {1}" -f $queryFile, $csvPath)
  if ($useHostSqlcmd) {
    Export-WithHostSqlcmd -QueryPath $queryPath -RawOutputPath $rawPath
  }
  else {
    Export-WithDockerSqlcmd -QueryPath $queryPath -RawOutputPath $rawPath
  }

  $finalLines = [System.Collections.Generic.List[string]]::new()
  $finalLines.Add($spec.Header)
  if (Test-Path $rawPath) {
    $dataLines = Get-Content -Encoding UTF8 $rawPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    foreach ($line in $dataLines) {
      $finalLines.Add($line)
    }
  }
  $finalLines | Set-Content -Encoding UTF8 $csvPath
  Remove-Item -Force $rawPath -ErrorAction SilentlyContinue
}

$manifestPath = Join-Path $outDir "manifest.json"
$manifest = [pscustomobject]@{
  runId = $RunId
  generatedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
  server = $Server
  database = $Database
  outputDir = $outDir
  mode = $(if ($useHostSqlcmd) { "host-sqlcmd" } else { "docker-sqlcmd" })
  sqlContainerName = $SqlContainerName
  files = ($querySpecs | ForEach-Object { $_.Csv })
}
$manifest | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 $manifestPath

Write-Host "[OK] reverse export completed."
Write-Host ("[OK] outputDir={0}" -f $outDir)
Write-Host ("[OK] manifest={0}" -f $manifestPath)
