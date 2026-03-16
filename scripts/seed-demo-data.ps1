[CmdletBinding()]
param(
  [string]$Database = "SCM_RFT_PRODLIKE",
  [string]$SqlContainerName = "scm-sqlserver",
  [string]$EnvFile = ".env.production",
  [bool]$ApplyMigrations = $true
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$seedPasswordHash = '$2a$10$dFSWpkXBf.JGLtCo6ZeHoOrLGzptkVbtfb7hJ2K4SvdWk3kctTOY6'
$runId = "DEMO-SEED-$(Get-Date -Format yyyyMMdd-HHmmss)"
$evidenceDir = Join-Path $repoRoot "runbooks/evidence/$runId"
$summaryPath = Join-Path $evidenceDir "demo-seed-summary.md"

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

function Assert-DockerReady {
  param([Parameter(Mandatory = $true)][string]$ContainerName)

  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "[FAIL] docker command not found."
  }

  cmd /c "docker info >nul 2>nul"
  if ($LASTEXITCODE -ne 0) {
    throw "[FAIL] docker daemon is not running."
  }

  $runningContainers = docker ps --format "{{.Names}}"
  if (($runningContainers | Where-Object { $_ -eq $ContainerName }).Count -eq 0) {
    throw "[FAIL] SQL container '$ContainerName' is not running. Start the SQL container first."
  }
}

function Invoke-SqlBatch {
  param(
    [Parameter(Mandatory = $true)][string]$ContainerName,
    [Parameter(Mandatory = $true)][string]$DatabaseName,
    [Parameter(Mandatory = $true)][string]$SaPassword,
    [Parameter(Mandatory = $true)][string]$Sql
  )

  $cmd = @(
    "exec", $ContainerName,
    "/opt/mssql-tools18/bin/sqlcmd",
    "-S", "localhost",
    "-U", "sa",
    "-P", $SaPassword,
    "-C",
    "-d", $DatabaseName,
    "-b",
    "-Q", $Sql
  )

  & docker @cmd
  if ($LASTEXITCODE -ne 0) {
    throw "[FAIL] sql batch failed against $DatabaseName."
  }
}

function Ensure-Database {
  param(
    [Parameter(Mandatory = $true)][string]$ContainerName,
    [Parameter(Mandatory = $true)][string]$DatabaseName,
    [Parameter(Mandatory = $true)][string]$SaPassword
  )

  $createDbSql = "IF DB_ID(N'$DatabaseName') IS NULL BEGIN EXEC(N'CREATE DATABASE [$DatabaseName]'); END;"
  Invoke-SqlBatch -ContainerName $ContainerName -DatabaseName "master" -SaPassword $SaPassword -Sql $createDbSql
}

function Apply-MigrationFiles {
  param(
    [Parameter(Mandatory = $true)][string]$RepoRoot,
    [Parameter(Mandatory = $true)][string]$ContainerName,
    [Parameter(Mandatory = $true)][string]$DatabaseName,
    [Parameter(Mandatory = $true)][string]$SaPassword
  )

  $migrationFiles = @(
    "migration/flyway/V1__baseline.sql",
    "migration/flyway/V2__core_domains.sql",
    "migration/flyway/V3__auth_member_lookup_indexes.sql",
    "migration/flyway/V4__auth_credentials.sql",
    "migration/flyway/V5__member_search_tuning_indexes.sql",
    "migration/flyway/V6__quality_doc_ack_type.sql",
    "migration/flyway/V7__order_lot_query_indexes.sql"
  )

  foreach ($relPath in $migrationFiles) {
    $fullPath = Join-Path $RepoRoot $relPath
    if (-not (Test-Path $fullPath)) {
      throw "[FAIL] migration file not found: $relPath"
    }

    $sqlText = Get-Content -Raw -Encoding UTF8 $fullPath
    $batches = [regex]::Split($sqlText, "(?im)^\s*GO\s*$") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    foreach ($batch in $batches) {
      Invoke-SqlBatch -ContainerName $ContainerName -DatabaseName $DatabaseName -SaPassword $SaPassword -Sql $batch
    }
  }
}

function Write-DemoSummary {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$DatabaseName,
    [Parameter(Mandatory = $true)][string]$RunIdentifier
  )

  $content = @"
# Demo Seed Summary

- RunId: $RunIdentifier
- Database: $DatabaseName
- Default password for all demo logins: password

## Demo Logins
- `smoke-user`
- `smoke-admin`
- `demo-buyer-001`
- `demo-buyer-002`
- `demo-quality-001`
- `demo-warehouse-001`
- `demo-ops-001`
- `demo-vendor-alpha`
- `demo-vendor-beta`
- `demo-auditor-001`
- `demo-viewer-001`

## Search Hints
- Member search keyword: `demo`
- Order search keyword: `DEMO-ORDER`
- Board search keyword: `Demo`
- Quality-doc search keyword: `Demo`
- Inventory item code: `ITEM-001`
- Inventory warehouse code: `WH-01`

## Sample IDs
- Order detail: `DEMO-ORDER-1002`
- Lot detail: `DEMO-LOT-1002-A`
- Board post detail: `55555555-5555-5555-5555-000000000002`
- Quality document detail: `66666666-6666-6666-6666-000000000002`
- File detail: `44444444-4444-4444-4444-000000000003`
- Report job detail: `77777777-7777-7777-7777-000000000001`

## Coverage
- Members: 11 logins + inactive member
- Orders: 8
- Lots: 11
- Board posts: 5
- Quality documents: 4
- Inventory balances: 5
- Inventory movements: 8
- Upload files: 6
- Report jobs: 4
"@

  $directory = Split-Path -Parent $Path
  New-Item -ItemType Directory -Force $directory | Out-Null
  Set-Content -Path $Path -Value $content -Encoding UTF8
}

$envPath = Join-Path $repoRoot $EnvFile
$saPassword = Get-EnvValue -FilePath $envPath -Key "MSSQL_SA_PASSWORD"
if ([string]::IsNullOrWhiteSpace($saPassword)) {
  throw "[FAIL] MSSQL_SA_PASSWORD not found in $EnvFile"
}

Assert-DockerReady -ContainerName $SqlContainerName
Ensure-Database -ContainerName $SqlContainerName -DatabaseName $Database -SaPassword $saPassword

if ($ApplyMigrations) {
  Apply-MigrationFiles -RepoRoot $repoRoot -ContainerName $SqlContainerName -DatabaseName $Database -SaPassword $saPassword
}

$sql = @"
MERGE dbo.members AS target
USING (
    VALUES
      (N'smoke-user', N'Smoke User', N'ACTIVE'),
      (N'smoke-admin', N'Smoke Admin', N'ACTIVE'),
      (N'smoke-inactive', N'Smoke Inactive', N'INACTIVE'),
      (N'demo-buyer-001', N'Demo Buyer 001', N'ACTIVE'),
      (N'demo-buyer-002', N'Demo Buyer 002', N'ACTIVE'),
      (N'demo-quality-001', N'Demo Quality 001', N'ACTIVE'),
      (N'demo-warehouse-001', N'Demo Warehouse 001', N'ACTIVE'),
      (N'demo-ops-001', N'Demo Ops 001', N'ACTIVE'),
      (N'demo-vendor-alpha', N'Demo Vendor Alpha', N'ACTIVE'),
      (N'demo-vendor-beta', N'Demo Vendor Beta', N'ACTIVE'),
      (N'demo-auditor-001', N'Demo Auditor 001', N'ACTIVE'),
      (N'demo-viewer-001', N'Demo Viewer 001', N'ACTIVE'),
      (N'demo-inactive-001', N'Demo Inactive 001', N'INACTIVE')
) AS source(member_id, member_name, status)
ON target.member_id = source.member_id
WHEN MATCHED THEN
    UPDATE SET
      member_name = source.member_name,
      status = source.status,
      updated_at = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (member_id, member_name, status, created_at, updated_at)
    VALUES (source.member_id, source.member_name, source.status, SYSUTCDATETIME(), SYSUTCDATETIME());

MERGE dbo.auth_credentials AS target
USING (
    VALUES
      (N'smoke-user', N'smoke-user', N'$seedPasswordHash'),
      (N'smoke-admin', N'smoke-admin', N'$seedPasswordHash'),
      (N'demo-buyer-001', N'demo-buyer-001', N'$seedPasswordHash'),
      (N'demo-buyer-002', N'demo-buyer-002', N'$seedPasswordHash'),
      (N'demo-quality-001', N'demo-quality-001', N'$seedPasswordHash'),
      (N'demo-warehouse-001', N'demo-warehouse-001', N'$seedPasswordHash'),
      (N'demo-ops-001', N'demo-ops-001', N'$seedPasswordHash'),
      (N'demo-vendor-alpha', N'demo-vendor-alpha', N'$seedPasswordHash'),
      (N'demo-vendor-beta', N'demo-vendor-beta', N'$seedPasswordHash'),
      (N'demo-auditor-001', N'demo-auditor-001', N'$seedPasswordHash'),
      (N'demo-viewer-001', N'demo-viewer-001', N'$seedPasswordHash')
) AS source(login_id, member_id, password_hash)
ON target.login_id = source.login_id
WHEN MATCHED THEN
    UPDATE SET
      member_id = source.member_id,
      password_hash = source.password_hash,
      password_algo = N'BCRYPT',
      failed_count = 0,
      locked_until = NULL,
      updated_at = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (login_id, member_id, password_hash, password_algo, failed_count, locked_until, created_at, updated_at)
    VALUES (source.login_id, source.member_id, source.password_hash, N'BCRYPT', 0, NULL, SYSUTCDATETIME(), SYSUTCDATETIME());

MERGE dbo.upload_files AS target
USING (
    VALUES
      (CAST(N'44444444-4444-4444-4444-000000000001' AS UNIQUEIDENTIFIER), N'BOARD:DEMO-001', N'demo/board/demo-checklist.pdf', N'demo-checklist.pdf', DATEADD(DAY, -8, SYSUTCDATETIME())),
      (CAST(N'44444444-4444-4444-4444-000000000002' AS UNIQUEIDENTIFIER), N'QUALITY:DOC-001', N'demo/quality/demo-coa.pdf', N'demo-coa.pdf', DATEADD(DAY, -6, SYSUTCDATETIME())),
      (CAST(N'44444444-4444-4444-4444-000000000003' AS UNIQUEIDENTIFIER), N'REPORT:JOB-001', N'demo/report/daily-summary.csv', N'daily-summary.csv', DATEADD(DAY, -2, SYSUTCDATETIME())),
      (CAST(N'44444444-4444-4444-4444-000000000004' AS UNIQUEIDENTIFIER), N'BOARD:DEMO-002', N'demo/board/vendor-guide.docx', N'vendor-guide.docx', DATEADD(DAY, -4, SYSUTCDATETIME())),
      (CAST(N'44444444-4444-4444-4444-000000000005' AS UNIQUEIDENTIFIER), N'QUALITY:DOC-002', N'demo/quality/audit-checklist.xlsx', N'audit-checklist.xlsx', DATEADD(DAY, -3, SYSUTCDATETIME())),
      (CAST(N'44444444-4444-4444-4444-000000000006' AS UNIQUEIDENTIFIER), N'REPORT:JOB-004', N'demo/report/order-status.xlsx', N'order-status.xlsx', DATEADD(DAY, -1, SYSUTCDATETIME()))
) AS source(file_id, domain_key, storage_path, original_name, created_at)
ON target.file_id = source.file_id
WHEN MATCHED THEN
    UPDATE SET
      domain_key = source.domain_key,
      storage_path = source.storage_path,
      original_name = source.original_name,
      created_at = source.created_at
WHEN NOT MATCHED THEN
    INSERT (file_id, domain_key, storage_path, original_name, created_at)
    VALUES (source.file_id, source.domain_key, source.storage_path, source.original_name, source.created_at);

MERGE dbo.orders AS target
USING (
    VALUES
      (N'DEMO-ORDER-1001', N'demo-buyer-001', DATEADD(DAY, -10, CAST(GETDATE() AS DATE)), N'PENDING', DATEADD(DAY, -10, SYSUTCDATETIME())),
      (N'DEMO-ORDER-1002', N'demo-buyer-001', DATEADD(DAY, -8, CAST(GETDATE() AS DATE)), N'CONFIRMED', DATEADD(DAY, -8, SYSUTCDATETIME())),
      (N'DEMO-ORDER-1003', N'demo-buyer-002', DATEADD(DAY, -6, CAST(GETDATE() AS DATE)), N'IN_PROGRESS', DATEADD(DAY, -6, SYSUTCDATETIME())),
      (N'DEMO-ORDER-1004', N'demo-vendor-alpha', DATEADD(DAY, -4, CAST(GETDATE() AS DATE)), N'COMPLETED', DATEADD(DAY, -4, SYSUTCDATETIME())),
      (N'DEMO-ORDER-1005', N'demo-vendor-beta', DATEADD(DAY, -3, CAST(GETDATE() AS DATE)), N'CONFIRMED', DATEADD(DAY, -3, SYSUTCDATETIME())),
      (N'DEMO-ORDER-1006', N'smoke-user', DATEADD(DAY, -2, CAST(GETDATE() AS DATE)), N'PENDING', DATEADD(DAY, -2, SYSUTCDATETIME())),
      (N'DEMO-ORDER-1007', N'demo-ops-001', DATEADD(DAY, -1, CAST(GETDATE() AS DATE)), N'COMPLETED', DATEADD(DAY, -1, SYSUTCDATETIME())),
      (N'DEMO-ORDER-1008', N'demo-buyer-002', CAST(GETDATE() AS DATE), N'CANCELED', SYSUTCDATETIME())
) AS source(order_no, member_id, order_date, status, created_at)
ON target.order_no = source.order_no
WHEN MATCHED THEN
    UPDATE SET
      member_id = source.member_id,
      order_date = source.order_date,
      status = source.status,
      created_at = source.created_at
WHEN NOT MATCHED THEN
    INSERT (order_no, member_id, order_date, status, created_at)
    VALUES (source.order_no, source.member_id, source.order_date, source.status, source.created_at);

MERGE dbo.order_lots AS target
USING (
    VALUES
      (N'DEMO-LOT-1001-A', N'DEMO-ORDER-1001', CAST(12.500 AS DECIMAL(18,3)), N'READY', DATEADD(DAY, -10, SYSUTCDATETIME())),
      (N'DEMO-LOT-1001-B', N'DEMO-ORDER-1001', CAST(4.000 AS DECIMAL(18,3)), N'READY', DATEADD(DAY, -10, SYSUTCDATETIME())),
      (N'DEMO-LOT-1002-A', N'DEMO-ORDER-1002', CAST(16.250 AS DECIMAL(18,3)), N'READY', DATEADD(DAY, -8, SYSUTCDATETIME())),
      (N'DEMO-LOT-1002-B', N'DEMO-ORDER-1002', CAST(5.500 AS DECIMAL(18,3)), N'IN_PROGRESS', DATEADD(DAY, -8, SYSUTCDATETIME())),
      (N'DEMO-LOT-1003-A', N'DEMO-ORDER-1003', CAST(8.750 AS DECIMAL(18,3)), N'IN_PROGRESS', DATEADD(DAY, -6, SYSUTCDATETIME())),
      (N'DEMO-LOT-1003-B', N'DEMO-ORDER-1003', CAST(2.000 AS DECIMAL(18,3)), N'READY', DATEADD(DAY, -6, SYSUTCDATETIME())),
      (N'DEMO-LOT-1004-A', N'DEMO-ORDER-1004', CAST(20.000 AS DECIMAL(18,3)), N'COMPLETED', DATEADD(DAY, -4, SYSUTCDATETIME())),
      (N'DEMO-LOT-1005-A', N'DEMO-ORDER-1005', CAST(15.000 AS DECIMAL(18,3)), N'READY', DATEADD(DAY, -3, SYSUTCDATETIME())),
      (N'DEMO-LOT-1006-A', N'DEMO-ORDER-1006', CAST(9.000 AS DECIMAL(18,3)), N'READY', DATEADD(DAY, -2, SYSUTCDATETIME())),
      (N'DEMO-LOT-1007-A', N'DEMO-ORDER-1007', CAST(6.250 AS DECIMAL(18,3)), N'COMPLETED', DATEADD(DAY, -1, SYSUTCDATETIME())),
      (N'DEMO-LOT-1008-A', N'DEMO-ORDER-1008', CAST(3.500 AS DECIMAL(18,3)), N'READY', SYSUTCDATETIME())
) AS source(lot_no, order_no, quantity, status, created_at)
ON target.lot_no = source.lot_no
WHEN MATCHED THEN
    UPDATE SET
      order_no = source.order_no,
      quantity = source.quantity,
      status = source.status,
      created_at = source.created_at
WHEN NOT MATCHED THEN
    INSERT (lot_no, order_no, quantity, status, created_at)
    VALUES (source.lot_no, source.order_no, source.quantity, source.status, source.created_at);

MERGE dbo.board_posts AS target
USING (
    VALUES
      (CAST(N'55555555-5555-5555-5555-000000000001' AS UNIQUEIDENTIFIER), N'GENERAL', N'Demo launch checklist', N'Checklist for the internal SCM demonstration.', N'demo-ops-001', CAST(0 AS BIT), N'ACTIVE', DATEADD(DAY, -8, SYSUTCDATETIME()), DATEADD(DAY, -8, SYSUTCDATETIME())),
      (CAST(N'55555555-5555-5555-5555-000000000002' AS UNIQUEIDENTIFIER), N'NOTICE', N'Demo maintenance window', N'Read-only validation before write-open switch.', N'smoke-admin', CAST(1 AS BIT), N'ACTIVE', DATEADD(DAY, -6, SYSUTCDATETIME()), DATEADD(DAY, -6, SYSUTCDATETIME())),
      (CAST(N'55555555-5555-5555-5555-000000000003' AS UNIQUEIDENTIFIER), N'QUALITY', N'Demo quality escalation route', N'Escalate supplier quality issues to demo-quality-001.', N'demo-quality-001', CAST(0 AS BIT), N'ACTIVE', DATEADD(DAY, -4, SYSUTCDATETIME()), DATEADD(DAY, -4, SYSUTCDATETIME())),
      (CAST(N'55555555-5555-5555-5555-000000000004' AS UNIQUEIDENTIFIER), N'GENERAL', N'Vendor alpha onboarding pack', N'Board post used to show file attachment references.', N'demo-vendor-alpha', CAST(0 AS BIT), N'ACTIVE', DATEADD(DAY, -3, SYSUTCDATETIME()), DATEADD(DAY, -3, SYSUTCDATETIME())),
      (CAST(N'55555555-5555-5555-5555-000000000005' AS UNIQUEIDENTIFIER), N'NOTICE', N'Smoke account quick guide', N'Use smoke-user or demo-buyer-001 during the portal walk-through.', N'smoke-admin', CAST(1 AS BIT), N'ACTIVE', DATEADD(DAY, -1, SYSUTCDATETIME()), DATEADD(DAY, -1, SYSUTCDATETIME()))
) AS source(post_id, category_code, title, content, writer_member_id, is_notice, status, created_at, updated_at)
ON target.post_id = source.post_id
WHEN MATCHED THEN
    UPDATE SET
      category_code = source.category_code,
      title = source.title,
      content = source.content,
      writer_member_id = source.writer_member_id,
      is_notice = source.is_notice,
      status = source.status,
      created_at = source.created_at,
      updated_at = source.updated_at
WHEN NOT MATCHED THEN
    INSERT (post_id, category_code, title, content, writer_member_id, is_notice, status, created_at, updated_at)
    VALUES (source.post_id, source.category_code, source.title, source.content, source.writer_member_id, source.is_notice, source.status, source.created_at, source.updated_at);

MERGE dbo.board_post_attachments AS target
USING (
    VALUES
      (CAST(N'55555555-5555-5555-5555-000000000001' AS UNIQUEIDENTIFIER), CAST(N'44444444-4444-4444-4444-000000000001' AS UNIQUEIDENTIFIER), DATEADD(DAY, -8, SYSUTCDATETIME())),
      (CAST(N'55555555-5555-5555-5555-000000000004' AS UNIQUEIDENTIFIER), CAST(N'44444444-4444-4444-4444-000000000004' AS UNIQUEIDENTIFIER), DATEADD(DAY, -3, SYSUTCDATETIME())),
      (CAST(N'55555555-5555-5555-5555-000000000003' AS UNIQUEIDENTIFIER), CAST(N'44444444-4444-4444-4444-000000000005' AS UNIQUEIDENTIFIER), DATEADD(DAY, -4, SYSUTCDATETIME()))
) AS source(post_id, file_id, created_at)
ON target.post_id = source.post_id AND target.file_id = source.file_id
WHEN NOT MATCHED THEN
    INSERT (post_id, file_id, created_at)
    VALUES (source.post_id, source.file_id, source.created_at);

MERGE dbo.quality_documents AS target
USING (
    VALUES
      (CAST(N'66666666-6666-6666-6666-000000000001' AS UNIQUEIDENTIFIER), N'Demo incoming inspection notice', N'NOTICE', DATEADD(DAY, -7, SYSUTCDATETIME()), N'demo-quality-001', N'ISSUED', DATEADD(DAY, -7, SYSUTCDATETIME()), DATEADD(DAY, -7, SYSUTCDATETIME())),
      (CAST(N'66666666-6666-6666-6666-000000000002' AS UNIQUEIDENTIFIER), N'Demo certificate of analysis', N'COA', DATEADD(DAY, -5, SYSUTCDATETIME()), N'demo-quality-001', N'RECEIVED', DATEADD(DAY, -5, SYSUTCDATETIME()), DATEADD(DAY, -5, SYSUTCDATETIME())),
      (CAST(N'66666666-6666-6666-6666-000000000003' AS UNIQUEIDENTIFIER), N'Demo supplier audit report', N'AUDIT', DATEADD(DAY, -4, SYSUTCDATETIME()), N'demo-auditor-001', N'ARCHIVED', DATEADD(DAY, -4, SYSUTCDATETIME()), DATEADD(DAY, -4, SYSUTCDATETIME())),
      (CAST(N'66666666-6666-6666-6666-000000000004' AS UNIQUEIDENTIFIER), N'Demo packaging standard', N'GUIDE', DATEADD(DAY, -2, SYSUTCDATETIME()), N'demo-quality-001', N'ISSUED', DATEADD(DAY, -2, SYSUTCDATETIME()), DATEADD(DAY, -2, SYSUTCDATETIME()))
) AS source(document_id, title, document_type, issued_at, publisher_member_id, status, created_at, updated_at)
ON target.document_id = source.document_id
WHEN MATCHED THEN
    UPDATE SET
      title = source.title,
      document_type = source.document_type,
      issued_at = source.issued_at,
      publisher_member_id = source.publisher_member_id,
      status = source.status,
      created_at = source.created_at,
      updated_at = source.updated_at
WHEN NOT MATCHED THEN
    INSERT (document_id, title, document_type, issued_at, publisher_member_id, status, created_at, updated_at)
    VALUES (source.document_id, source.title, source.document_type, source.issued_at, source.publisher_member_id, source.status, source.created_at, source.updated_at);

MERGE dbo.quality_document_acks AS target
USING (
    VALUES
      (CAST(N'66666666-6666-6666-6666-000000000002' AS UNIQUEIDENTIFIER), N'demo-buyer-001', N'READ', DATEADD(DAY, -4, SYSUTCDATETIME()), DATEADD(DAY, -4, SYSUTCDATETIME())),
      (CAST(N'66666666-6666-6666-6666-000000000002' AS UNIQUEIDENTIFIER), N'demo-quality-001', N'CONFIRMED', DATEADD(DAY, -4, SYSUTCDATETIME()), DATEADD(DAY, -4, SYSUTCDATETIME())),
      (CAST(N'66666666-6666-6666-6666-000000000004' AS UNIQUEIDENTIFIER), N'demo-buyer-002', N'READ', DATEADD(HOUR, -12, SYSUTCDATETIME()), DATEADD(HOUR, -12, SYSUTCDATETIME()))
) AS source(document_id, member_id, ack_type, ack_at, created_at)
ON target.document_id = source.document_id AND target.member_id = source.member_id
WHEN MATCHED THEN
    UPDATE SET
      ack_type = source.ack_type,
      ack_at = source.ack_at,
      created_at = source.created_at
WHEN NOT MATCHED THEN
    INSERT (document_id, member_id, ack_type, ack_at, created_at)
    VALUES (source.document_id, source.member_id, source.ack_type, source.ack_at, source.created_at);

MERGE dbo.inventory_balances AS target
USING (
    VALUES
      (N'ITEM-001', N'WH-01', CAST(120.000 AS DECIMAL(18,3)), DATEADD(HOUR, -6, SYSUTCDATETIME())),
      (N'ITEM-001', N'WH-02', CAST(32.500 AS DECIMAL(18,3)), DATEADD(HOUR, -5, SYSUTCDATETIME())),
      (N'ITEM-DEMO-01', N'WH-01', CAST(250.000 AS DECIMAL(18,3)), DATEADD(HOUR, -4, SYSUTCDATETIME())),
      (N'ITEM-DEMO-02', N'WH-01', CAST(18.000 AS DECIMAL(18,3)), DATEADD(HOUR, -3, SYSUTCDATETIME())),
      (N'ITEM-DEMO-03', N'WH-02', CAST(64.250 AS DECIMAL(18,3)), DATEADD(HOUR, -2, SYSUTCDATETIME()))
) AS source(item_code, warehouse_code, quantity, updated_at)
ON target.item_code = source.item_code AND target.warehouse_code = source.warehouse_code
WHEN MATCHED THEN
    UPDATE SET
      quantity = source.quantity,
      updated_at = source.updated_at
WHEN NOT MATCHED THEN
    INSERT (item_code, warehouse_code, quantity, updated_at)
    VALUES (source.item_code, source.warehouse_code, source.quantity, source.updated_at);

MERGE dbo.inventory_movements AS target
USING (
    VALUES
      (CAST(N'88888888-8888-8888-8888-000000000001' AS UNIQUEIDENTIFIER), N'ITEM-001', N'WH-01', N'IN', CAST(100.000 AS DECIMAL(18,3)), N'DEMO-GRN-001', DATEADD(DAY, -3, SYSUTCDATETIME()), DATEADD(DAY, -3, SYSUTCDATETIME())),
      (CAST(N'88888888-8888-8888-8888-000000000002' AS UNIQUEIDENTIFIER), N'ITEM-001', N'WH-01', N'OUT', CAST(12.000 AS DECIMAL(18,3)), N'DEMO-SHIP-001', DATEADD(DAY, -2, SYSUTCDATETIME()), DATEADD(DAY, -2, SYSUTCDATETIME())),
      (CAST(N'88888888-8888-8888-8888-000000000003' AS UNIQUEIDENTIFIER), N'ITEM-001', N'WH-02', N'ADJUST', CAST(2.500 AS DECIMAL(18,3)), N'DEMO-ADJ-001', DATEADD(DAY, -1, SYSUTCDATETIME()), DATEADD(DAY, -1, SYSUTCDATETIME())),
      (CAST(N'88888888-8888-8888-8888-000000000004' AS UNIQUEIDENTIFIER), N'ITEM-DEMO-01', N'WH-01', N'IN', CAST(250.000 AS DECIMAL(18,3)), N'DEMO-GRN-002', DATEADD(DAY, -5, SYSUTCDATETIME()), DATEADD(DAY, -5, SYSUTCDATETIME())),
      (CAST(N'88888888-8888-8888-8888-000000000005' AS UNIQUEIDENTIFIER), N'ITEM-DEMO-01', N'WH-01', N'OUT', CAST(20.000 AS DECIMAL(18,3)), N'DEMO-SHIP-002', DATEADD(DAY, -4, SYSUTCDATETIME()), DATEADD(DAY, -4, SYSUTCDATETIME())),
      (CAST(N'88888888-8888-8888-8888-000000000006' AS UNIQUEIDENTIFIER), N'ITEM-DEMO-02', N'WH-01', N'IN', CAST(18.000 AS DECIMAL(18,3)), N'DEMO-GRN-003', DATEADD(DAY, -3, SYSUTCDATETIME()), DATEADD(DAY, -3, SYSUTCDATETIME())),
      (CAST(N'88888888-8888-8888-8888-000000000007' AS UNIQUEIDENTIFIER), N'ITEM-DEMO-03', N'WH-02', N'IN', CAST(64.250 AS DECIMAL(18,3)), N'DEMO-GRN-004', DATEADD(DAY, -2, SYSUTCDATETIME()), DATEADD(DAY, -2, SYSUTCDATETIME())),
      (CAST(N'88888888-8888-8888-8888-000000000008' AS UNIQUEIDENTIFIER), N'ITEM-DEMO-03', N'WH-02', N'OUT', CAST(4.250 AS DECIMAL(18,3)), N'DEMO-SHIP-003', DATEADD(DAY, -1, SYSUTCDATETIME()), DATEADD(DAY, -1, SYSUTCDATETIME()))
) AS source(movement_id, item_code, warehouse_code, movement_type, quantity, reference_no, moved_at, created_at)
ON target.movement_id = source.movement_id
WHEN MATCHED THEN
    UPDATE SET
      item_code = source.item_code,
      warehouse_code = source.warehouse_code,
      movement_type = source.movement_type,
      quantity = source.quantity,
      reference_no = source.reference_no,
      moved_at = source.moved_at,
      created_at = source.created_at
WHEN NOT MATCHED THEN
    INSERT (movement_id, item_code, warehouse_code, movement_type, quantity, reference_no, moved_at, created_at)
    VALUES (source.movement_id, source.item_code, source.warehouse_code, source.movement_type, source.quantity, source.reference_no, source.moved_at, source.created_at);

MERGE dbo.report_jobs AS target
USING (
    VALUES
      (CAST(N'77777777-7777-7777-7777-000000000001' AS UNIQUEIDENTIFIER), N'P0_DAILY', N'demo-ops-001', N'COMPLETED', DATEADD(DAY, -1, SYSUTCDATETIME()), DATEADD(HOUR, -20, SYSUTCDATETIME()), CAST(N'44444444-4444-4444-4444-000000000003' AS UNIQUEIDENTIFIER), CAST(NULL AS NVARCHAR(1000))),
      (CAST(N'77777777-7777-7777-7777-000000000002' AS UNIQUEIDENTIFIER), N'INVENTORY_AGING', N'demo-warehouse-001', N'RUNNING', DATEADD(HOUR, -8, SYSUTCDATETIME()), CAST(NULL AS DATETIME2), CAST(NULL AS UNIQUEIDENTIFIER), CAST(NULL AS NVARCHAR(1000))),
      (CAST(N'77777777-7777-7777-7777-000000000003' AS UNIQUEIDENTIFIER), N'QUALITY_SUMMARY', N'demo-quality-001', N'QUEUED', DATEADD(HOUR, -4, SYSUTCDATETIME()), CAST(NULL AS DATETIME2), CAST(NULL AS UNIQUEIDENTIFIER), CAST(NULL AS NVARCHAR(1000))),
      (CAST(N'77777777-7777-7777-7777-000000000004' AS UNIQUEIDENTIFIER), N'ORDER_STATUS', N'demo-buyer-001', N'FAILED', DATEADD(HOUR, -2, SYSUTCDATETIME()), DATEADD(HOUR, -1, SYSUTCDATETIME()), CAST(NULL AS UNIQUEIDENTIFIER), N'Demo failure sample for alert walkthrough')
) AS source(job_id, report_type, requested_by_member_id, status, requested_at, completed_at, output_file_id, error_message)
ON target.job_id = source.job_id
WHEN MATCHED THEN
    UPDATE SET
      report_type = source.report_type,
      requested_by_member_id = source.requested_by_member_id,
      status = source.status,
      requested_at = source.requested_at,
      completed_at = source.completed_at,
      output_file_id = source.output_file_id,
      error_message = source.error_message
WHEN NOT MATCHED THEN
    INSERT (job_id, report_type, requested_by_member_id, status, requested_at, completed_at, output_file_id, error_message)
    VALUES (source.job_id, source.report_type, source.requested_by_member_id, source.status, source.requested_at, source.completed_at, source.output_file_id, source.error_message);
"@

Invoke-SqlBatch -ContainerName $SqlContainerName -DatabaseName $Database -SaPassword $saPassword -Sql $sql
Write-DemoSummary -Path $summaryPath -DatabaseName $Database -RunIdentifier $runId
Write-Host "[OK] demo seed data upsert completed."
Write-Host "[OK] demo seed summary: $summaryPath"



