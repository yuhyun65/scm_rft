param(
  [string]$InputDir = "",
  [string]$ColumnsCsv = "",
  [string]$RelationsCsv = "",
  [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

function Normalize-EntityName {
  param(
    [string]$SchemaName,
    [string]$TableName
  )
  $raw = "{0}_{1}" -f $SchemaName, $TableName
  return ($raw -replace "[^A-Za-z0-9_]", "_")
}

function Parse-ColumnList {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) {
    return @()
  }
  return @(
    $Value -split "," |
    ForEach-Object { $_.Trim() } |
    ForEach-Object { $_ -replace "^\[", "" -replace "\]$", "" } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  )
}

if ([string]::IsNullOrWhiteSpace($InputDir)) {
  $baseDir = Join-Path $repoRoot "migration/reverse"
  if (-not (Test-Path $baseDir)) {
    throw "base directory not found: $baseDir"
  }
  $latest = Get-ChildItem -Path $baseDir -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $latest) {
    throw "no reverse export run directory found under $baseDir"
  }
  $InputDir = $latest.FullName
}
elseif (-not [System.IO.Path]::IsPathRooted($InputDir)) {
  $InputDir = Join-Path $repoRoot $InputDir
}

if ([string]::IsNullOrWhiteSpace($ColumnsCsv)) {
  $ColumnsCsv = Join-Path $InputDir "01_tables_columns.csv"
}
elseif (-not [System.IO.Path]::IsPathRooted($ColumnsCsv)) {
  $ColumnsCsv = Join-Path $repoRoot $ColumnsCsv
}

if ([string]::IsNullOrWhiteSpace($RelationsCsv)) {
  $RelationsCsv = Join-Path $InputDir "02_pk_uk_fk.csv"
}
elseif (-not [System.IO.Path]::IsPathRooted($RelationsCsv)) {
  $RelationsCsv = Join-Path $repoRoot $RelationsCsv
}

if ([string]::IsNullOrWhiteSpace($OutputFile)) {
  $OutputFile = Join-Path $InputDir "erd.mmd"
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputFile)) {
  $OutputFile = Join-Path $repoRoot $OutputFile
}

if (-not (Test-Path $ColumnsCsv)) {
  throw "columns csv not found: $ColumnsCsv"
}
if (-not (Test-Path $RelationsCsv)) {
  throw "relations csv not found: $RelationsCsv"
}

$columns = Import-Csv -Path $ColumnsCsv
$relations = Import-Csv -Path $RelationsCsv

$pkMap = @{}
$pkRows = $relations | Where-Object { $_.relation_type -eq "PK" }
foreach ($row in $pkRows) {
  $entity = Normalize-EntityName -SchemaName $row.parent_schema -TableName $row.parent_table
  if (-not $pkMap.ContainsKey($entity)) {
    $pkMap[$entity] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
  }
  $pkCols = Parse-ColumnList -Value $row.parent_columns
  foreach ($col in $pkCols) {
    [void]$pkMap[$entity].Add($col)
  }
}

$tableGroups = $columns | Group-Object table_schema, table_name | Sort-Object Name
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("erDiagram")

foreach ($group in $tableGroups) {
  $first = $group.Group | Select-Object -First 1
  $entity = Normalize-EntityName -SchemaName $first.table_schema -TableName $first.table_name
  $lines.Add(("  {0} {{" -f $entity))

  $orderedColumns = $group.Group | Sort-Object {[int]$_.column_id}
  foreach ($col in $orderedColumns) {
    $type = if ([string]::IsNullOrWhiteSpace($col.system_type)) { "nvarchar" } else { $col.system_type }
    $columnName = $col.column_name
    $pkSuffix = ""
    if ($pkMap.ContainsKey($entity) -and $pkMap[$entity].Contains($columnName)) {
      $pkSuffix = " PK"
    }
    $lines.Add(("    {0} {1}{2}" -f $type, $columnName, $pkSuffix))
  }
  $lines.Add("  }")
}

$fkRows = $relations | Where-Object { $_.relation_type -eq "FK" }
$relationSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($fk in $fkRows) {
  if ([string]::IsNullOrWhiteSpace($fk.referenced_schema) -or [string]::IsNullOrWhiteSpace($fk.referenced_table)) {
    continue
  }
  $child = Normalize-EntityName -SchemaName $fk.parent_schema -TableName $fk.parent_table
  $parent = Normalize-EntityName -SchemaName $fk.referenced_schema -TableName $fk.referenced_table
  $label = if ([string]::IsNullOrWhiteSpace($fk.constraint_name)) { "FK" } else { $fk.constraint_name }
  $relationLine = ("  {0} ||--o{{ {1} : ""{2}""" -f $parent, $child, $label)
  [void]$relationSet.Add($relationLine)
}

foreach ($rel in ($relationSet | Sort-Object)) {
  $lines.Add($rel)
}

$lines | Set-Content -Encoding UTF8 $OutputFile

Write-Host ("[OK] ERD generated: {0}" -f $OutputFile)
Write-Host ("[OK] Tables: {0}" -f $tableGroups.Count)
Write-Host ("[OK] FK Relations: {0}" -f $relationSet.Count)
