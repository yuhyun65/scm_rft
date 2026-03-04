[CmdletBinding()]
param(
  [string]$GatewayBaseUrl = "http://localhost:18080",
  [string]$Database = "MES_HI",
  [string]$SqlContainerName = "scm-stg-sqlserver",
  [string]$EnvFile = ".env.staging",
  [string]$LoginId = "smoke-user",
  [string]$Password = "password",
  [bool]$SeedData = $true
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$seedPasswordHash = '$2a$10$dFSWpkXBf.JGLtCo6ZeHoOrLGzptkVbtfb7hJ2K4SvdWk3kctTOY6'
$seedOrderId = "P0-ORDER-001"
$seedLotId = "P0-LOT-001"
$seedDocId = "11111111-1111-1111-1111-111111111111"

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

function Assert-Health {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Uri
  )

  try {
    $response = Invoke-RestMethod -Method Get -Uri $Uri -TimeoutSec 10
    if ($response.status -and "$($response.status)".ToUpperInvariant() -ne "UP") {
      throw "health status is not UP."
    }
    Write-Host ("[OK] {0} health check passed: {1}" -f $Name, $Uri)
  }
  catch {
    throw "[FAIL] $Name health check failed at $Uri."
  }
}

function Invoke-Login {
  param(
    [Parameter(Mandatory = $true)][string]$Uri,
    [Parameter(Mandatory = $true)][string]$LoginIdValue,
    [Parameter(Mandatory = $true)][string]$PasswordValue
  )

  return Invoke-RestMethod -Method Post -Uri $Uri -ContentType "application/json" -Body (@{
    loginId = $LoginIdValue
    password = $PasswordValue
  } | ConvertTo-Json)
}

function Seed-P0Data {
  param(
    [Parameter(Mandatory = $true)][string]$RepoRoot,
    [Parameter(Mandatory = $true)][string]$ContainerName,
    [Parameter(Mandatory = $true)][string]$TargetDatabase,
    [Parameter(Mandatory = $true)][string]$TargetEnvFile,
    [Parameter(Mandatory = $true)][string]$PasswordHash,
    [Parameter(Mandatory = $true)][string]$OrderId,
    [Parameter(Mandatory = $true)][string]$LotId,
    [Parameter(Mandatory = $true)][string]$DocId
  )

  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "[FAIL] docker command not found."
  }

  cmd /c "docker info >nul 2>nul"
  if ($LASTEXITCODE -ne 0) {
    throw "[FAIL] docker daemon is not running."
  }

  $runningContainers = docker ps --format "{{.Names}}"
  if (($runningContainers | Where-Object { $_ -eq $ContainerName }).Count -eq 0) {
    throw "[FAIL] SQL container '$ContainerName' is not running."
  }

  $saPassword = Get-EnvValue -FilePath (Join-Path $RepoRoot $TargetEnvFile) -Key "MSSQL_SA_PASSWORD"
  if ([string]::IsNullOrWhiteSpace($saPassword)) {
    throw "[FAIL] MSSQL_SA_PASSWORD not found in $TargetEnvFile"
  }

  $createDbSql = "IF DB_ID(N'$TargetDatabase') IS NULL BEGIN EXEC(N'CREATE DATABASE [$TargetDatabase]'); END;"
  $createDbCmd = @(
    "exec", $ContainerName,
    "/opt/mssql-tools18/bin/sqlcmd",
    "-S", "localhost",
    "-U", "sa",
    "-P", $saPassword,
    "-C",
    "-d", "master",
    "-b",
    "-Q", $createDbSql
  )
  & docker @createDbCmd
  if ($LASTEXITCODE -ne 0) {
    throw "[FAIL] database create/ensure failed for $TargetDatabase."
  }

  $migrationFiles = @(
    "migration/flyway/V1__baseline.sql",
    "migration/flyway/V2__core_domains.sql",
    "migration/flyway/V4__auth_credentials.sql",
    "migration/flyway/V5__member_search_tuning_indexes.sql"
  )

  foreach ($relPath in $migrationFiles) {
    $fullPath = Join-Path $RepoRoot $relPath
    if (-not (Test-Path $fullPath)) {
      throw "[FAIL] migration file not found: $relPath"
    }

    $sqlText = Get-Content -Raw -Encoding UTF8 $fullPath
    $batches = [regex]::Split($sqlText, "(?im)^\s*GO\s*$") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    foreach ($batch in $batches) {
      $migrationCmd = @(
        "exec", $ContainerName,
        "/opt/mssql-tools18/bin/sqlcmd",
        "-S", "localhost",
        "-U", "sa",
        "-P", $saPassword,
        "-C",
        "-d", $TargetDatabase,
        "-b",
        "-Q", $batch
      )
      & docker @migrationCmd
      if ($LASTEXITCODE -ne 0) {
        throw "[FAIL] migration apply failed: $relPath"
      }
    }
  }

  $sql = @"
MERGE dbo.members AS target
USING (
    VALUES
      (N'smoke-user', N'Smoke User', N'ACTIVE'),
      (N'smoke-admin', N'Smoke Admin', N'ACTIVE'),
      (N'smoke-inactive', N'Smoke Inactive', N'INACTIVE')
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
      (N'smoke-user', N'smoke-user', N'$PasswordHash'),
      (N'smoke-admin', N'smoke-admin', N'$PasswordHash')
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

MERGE dbo.orders AS target
USING (
    VALUES
      (N'$OrderId', N'smoke-user', CAST(GETDATE() AS DATE), N'PENDING')
) AS source(order_no, member_id, order_date, status)
ON target.order_no = source.order_no
WHEN MATCHED THEN
    UPDATE SET
      member_id = source.member_id,
      order_date = source.order_date,
      status = source.status,
      created_at = ISNULL(target.created_at, SYSUTCDATETIME())
WHEN NOT MATCHED THEN
    INSERT (order_no, member_id, order_date, status, created_at)
    VALUES (source.order_no, source.member_id, source.order_date, source.status, SYSUTCDATETIME());

MERGE dbo.order_lots AS target
USING (
    VALUES
      (N'$LotId', N'$OrderId', CAST(12.500 AS DECIMAL(18,3)), N'READY')
) AS source(lot_no, order_no, quantity, status)
ON target.lot_no = source.lot_no
WHEN MATCHED THEN
    UPDATE SET
      order_no = source.order_no,
      quantity = source.quantity,
      status = source.status,
      created_at = ISNULL(target.created_at, SYSUTCDATETIME())
WHEN NOT MATCHED THEN
    INSERT (lot_no, order_no, quantity, status, created_at)
    VALUES (source.lot_no, source.order_no, source.quantity, source.status, SYSUTCDATETIME());

MERGE dbo.inventory_balances AS target
USING (
    VALUES
      (N'ITEM-001', N'WH-01', CAST(100.000 AS DECIMAL(18,3)))
) AS source(item_code, warehouse_code, quantity)
ON target.item_code = source.item_code AND target.warehouse_code = source.warehouse_code
WHEN MATCHED THEN
    UPDATE SET
      quantity = source.quantity,
      updated_at = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (item_code, warehouse_code, quantity, updated_at)
    VALUES (source.item_code, source.warehouse_code, source.quantity, SYSUTCDATETIME());

MERGE dbo.inventory_movements AS target
USING (
    VALUES
      (CAST(N'33333333-3333-3333-3333-333333333333' AS UNIQUEIDENTIFIER), N'ITEM-001', N'WH-01', N'IN', CAST(100.000 AS DECIMAL(18,3)), N'P0-REF-001', SYSUTCDATETIME())
) AS source(movement_id, item_code, warehouse_code, movement_type, quantity, reference_no, moved_at)
ON target.movement_id = source.movement_id
WHEN MATCHED THEN
    UPDATE SET
      item_code = source.item_code,
      warehouse_code = source.warehouse_code,
      movement_type = source.movement_type,
      quantity = source.quantity,
      reference_no = source.reference_no,
      moved_at = source.moved_at
WHEN NOT MATCHED THEN
    INSERT (movement_id, item_code, warehouse_code, movement_type, quantity, reference_no, moved_at, created_at)
    VALUES (source.movement_id, source.item_code, source.warehouse_code, source.movement_type, source.quantity, source.reference_no, source.moved_at, SYSUTCDATETIME());

MERGE dbo.quality_documents AS target
USING (
    VALUES
      (CAST(N'$DocId' AS UNIQUEIDENTIFIER), N'P0 Quality Notice', N'NOTICE', SYSUTCDATETIME(), N'smoke-admin', N'ISSUED')
) AS source(document_id, title, document_type, issued_at, publisher_member_id, status)
ON target.document_id = source.document_id
WHEN MATCHED THEN
    UPDATE SET
      title = source.title,
      document_type = source.document_type,
      issued_at = source.issued_at,
      publisher_member_id = source.publisher_member_id,
      status = source.status,
      updated_at = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (document_id, title, document_type, issued_at, publisher_member_id, status, created_at, updated_at)
    VALUES (source.document_id, source.title, source.document_type, source.issued_at, source.publisher_member_id, source.status, SYSUTCDATETIME(), SYSUTCDATETIME());

MERGE dbo.board_posts AS target
USING (
    VALUES
      (CAST(N'22222222-2222-2222-2222-222222222222' AS UNIQUEIDENTIFIER), N'GENERAL', N'P0 board seeded post', N'P0 seed content', N'smoke-admin', CAST(0 AS BIT), N'ACTIVE')
) AS source(post_id, category_code, title, content, writer_member_id, is_notice, status)
ON target.post_id = source.post_id
WHEN MATCHED THEN
    UPDATE SET
      category_code = source.category_code,
      title = source.title,
      content = source.content,
      writer_member_id = source.writer_member_id,
      is_notice = source.is_notice,
      status = source.status,
      updated_at = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (post_id, category_code, title, content, writer_member_id, is_notice, status, created_at, updated_at)
    VALUES (source.post_id, source.category_code, source.title, source.content, source.writer_member_id, source.is_notice, source.status, SYSUTCDATETIME(), SYSUTCDATETIME());
"@

  $cmd = @(
    "exec", $ContainerName,
    "/opt/mssql-tools18/bin/sqlcmd",
    "-S", "localhost",
    "-U", "sa",
    "-P", $saPassword,
    "-C",
    "-d", $TargetDatabase,
    "-b",
    "-Q", $sql
  )

  & docker @cmd
  if ($LASTEXITCODE -ne 0) {
    throw "[FAIL] P0 seed data failed."
  }

  Write-Host "[OK] P0 seed data upsert completed."
}

function Assert-NotEmpty {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)]$Value
  )
  if ([string]::IsNullOrWhiteSpace([string]$Value)) {
    throw "[FAIL] $Name is empty."
  }
}

Push-Location $repoRoot
try {
  Assert-Health -Name "auth" -Uri "http://localhost:8081/actuator/health"
  Assert-Health -Name "member" -Uri "http://localhost:8082/actuator/health"
  Assert-Health -Name "board" -Uri "http://localhost:8083/actuator/health"
  Assert-Health -Name "quality-doc" -Uri "http://localhost:8084/actuator/health"
  Assert-Health -Name "order-lot" -Uri "http://localhost:8085/actuator/health"
  Assert-Health -Name "inventory" -Uri "http://localhost:8086/actuator/health"
  Assert-Health -Name "file" -Uri "http://localhost:8087/actuator/health"
  Assert-Health -Name "report" -Uri "http://localhost:8088/actuator/health"
  Assert-Health -Name "gateway" -Uri "http://localhost:18080/actuator/health"

  if ($SeedData) {
    Seed-P0Data -RepoRoot $repoRoot -ContainerName $SqlContainerName -TargetDatabase $Database -TargetEnvFile $EnvFile -PasswordHash $seedPasswordHash -OrderId $seedOrderId -LotId $seedLotId -DocId $seedDocId
  }
  else {
    Write-Host "[INFO] P0 seed data skipped."
  }

  $loginUri = "$GatewayBaseUrl/api/auth/v1/login"
  $verifyUri = "$GatewayBaseUrl/api/auth/v1/tokens/verify"

  try {
    Invoke-Login -Uri $loginUri -LoginIdValue $LoginId -PasswordValue $Password | Out-Null
    Write-Host "[INFO] login pre-warm request completed."
  }
  catch {
    Write-Host "[WARN] login pre-warm request failed. continue to formal login."
  }

  $loginResponse = $null
  for ($attempt = 1; $attempt -le 2; $attempt++) {
    try {
      $loginResponse = Invoke-Login -Uri $loginUri -LoginIdValue $LoginId -PasswordValue $Password
      break
    }
    catch {
      $statusCode = "unknown"
      if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
        $statusCode = [int]$_.Exception.Response.StatusCode
      }
      if ($statusCode -eq 504 -and $attempt -lt 2) {
        Write-Host "[WARN] login via gateway returned 504. retrying once..."
        Start-Sleep -Milliseconds 400
        continue
      }
      throw "[FAIL] login via gateway failed (HTTP $statusCode)."
    }
  }

  Assert-NotEmpty -Name "accessToken" -Value $loginResponse.accessToken
  Write-Host "[OK] P0-F01 login succeeded."

  $verifyResponse = Invoke-RestMethod -Method Post -Uri $verifyUri -ContentType "application/json" -Body (@{
    accessToken = "$($loginResponse.accessToken)"
  } | ConvertTo-Json)
  if (-not $verifyResponse.active) {
    throw "[FAIL] token verify returned inactive."
  }
  Write-Host "[OK] P0-F01 token verify succeeded."

  $authHeaders = @{ Authorization = "Bearer $($loginResponse.accessToken)" }

  $memberSearch = Invoke-RestMethod -Method Get -Uri "$GatewayBaseUrl/api/member/v1/members?status=ACTIVE&keyword=smoke&page=0&size=10" -Headers $authHeaders
  if (@($memberSearch.items).Count -lt 1) {
    throw "[FAIL] P0-F01 member search returned empty."
  }
  $memberDetail = Invoke-RestMethod -Method Get -Uri "$GatewayBaseUrl/api/member/v1/members/$LoginId" -Headers $authHeaders
  if ("$($memberDetail.memberId)" -ne $LoginId) {
    throw "[FAIL] P0-F01 member detail mismatch."
  }
  Write-Host "[OK] P0-F01 member search/detail passed."

  $orderList = Invoke-RestMethod -Method Get -Uri "$GatewayBaseUrl/api/order-lot/v1/orders?keyword=P0-ORDER&page=0&size=10" -Headers $authHeaders
  if (@($orderList.items).Count -lt 1) {
    throw "[FAIL] P0-F02 order list returned empty."
  }
  $orderId = "$($orderList.items[0].orderId)"
  if ([string]::IsNullOrWhiteSpace($orderId)) {
    $orderId = $seedOrderId
  }
  $orderDetail = Invoke-RestMethod -Method Get -Uri "$GatewayBaseUrl/api/order-lot/v1/orders/$orderId" -Headers $authHeaders
  if ("$($orderDetail.orderId)" -ne $orderId) {
    throw "[FAIL] P0-F02 order detail mismatch."
  }
  $lotDetail = Invoke-RestMethod -Method Get -Uri "$GatewayBaseUrl/api/order-lot/v1/lots/$seedLotId" -Headers $authHeaders
  if ("$($lotDetail.lotId)" -ne $seedLotId) {
    throw "[FAIL] P0-F02 lot detail mismatch."
  }
  $statusChange = Invoke-RestMethod -Method Post -Uri "$GatewayBaseUrl/api/order-lot/v1/orders/$orderId/status" -Headers $authHeaders -ContentType "application/json" -Body (@{
    targetStatus = "CONFIRMED"
    changedBy = "smoke-admin"
    reason = "P0 smoke transition"
  } | ConvertTo-Json)
  if ("$($statusChange.afterStatus)" -ne "CONFIRMED") {
    throw "[FAIL] P0-F02 status change mismatch."
  }
  Write-Host "[OK] P0-F02 order/lot flow passed."

  $fileCreate = Invoke-RestMethod -Method Post -Uri "$GatewayBaseUrl/api/file/v1/files" -Headers $authHeaders -ContentType "application/json" -Body (@{
    domainKey = "P0:BOARD"
    originalName = "p0-note.txt"
    storagePath = "p0/p0-note.txt"
  } | ConvertTo-Json)
  $fileId = "$($fileCreate.fileId)"
  Assert-NotEmpty -Name "fileId" -Value $fileId
  $fileDetail = Invoke-RestMethod -Method Get -Uri "$GatewayBaseUrl/api/file/v1/files/$fileId" -Headers $authHeaders
  if ("$($fileDetail.fileId)" -ne $fileId) {
    throw "[FAIL] P0-F03 file detail mismatch."
  }
  Write-Host "[OK] P0-F03 file register/get passed."

  $boardList = Invoke-RestMethod -Method Get -Uri "$GatewayBaseUrl/api/board/v1/posts?page=0&size=10" -Headers $authHeaders
  $postId = ""
  if (@($boardList.items).Count -ge 1) {
    $postId = "$($boardList.items[0].postId)"
  }
  if ([string]::IsNullOrWhiteSpace($postId)) {
    $boardCreate = Invoke-RestMethod -Method Post -Uri "$GatewayBaseUrl/api/board/v1/posts" -Headers $authHeaders -ContentType "application/json" -Body (@{
      boardType = "GENERAL"
      title = "P0 Smoke Post"
      content = "P0 smoke content"
      createdBy = "smoke-user"
      attachments = @()
    } | ConvertTo-Json -Depth 5)
    $postId = "$($boardCreate.postId)"
  }
  Assert-NotEmpty -Name "postId" -Value $postId
  $boardDetail = Invoke-RestMethod -Method Get -Uri "$GatewayBaseUrl/api/board/v1/posts/$postId" -Headers $authHeaders
  if ("$($boardDetail.postId)" -ne $postId) {
    throw "[FAIL] P0-F04 board detail mismatch."
  }
  Write-Host "[OK] P0-F04 board list/detail passed."

  $docList = Invoke-RestMethod -Method Get -Uri "$GatewayBaseUrl/api/quality-doc/v1/documents?page=0&size=10" -Headers $authHeaders
  if (@($docList.items).Count -lt 1) {
    throw "[FAIL] P0-F05 quality-doc list returned empty."
  }
  $docId = "$($docList.items[0].documentId)"
  if ([string]::IsNullOrWhiteSpace($docId)) {
    $docId = $seedDocId
  }
  $docDetail = Invoke-RestMethod -Method Get -Uri "$GatewayBaseUrl/api/quality-doc/v1/documents/$docId" -Headers $authHeaders
  if ("$($docDetail.documentId)" -ne $docId) {
    throw "[FAIL] P0-F05 quality-doc detail mismatch."
  }
  $ack = Invoke-RestMethod -Method Put -Uri "$GatewayBaseUrl/api/quality-doc/v1/documents/$docId/ack" -Headers $authHeaders -ContentType "application/json" -Body (@{
    memberId = "smoke-user"
    ackType = "READ"
    comment = "P0 smoke ack"
  } | ConvertTo-Json)
  if (-not $ack.acknowledged) {
    throw "[FAIL] P0-F05 quality-doc ack not acknowledged."
  }
  Write-Host "[OK] P0-F05 quality-doc list/detail/ack passed."

  $balances = Invoke-RestMethod -Method Get -Uri "$GatewayBaseUrl/api/inventory/v1/balances?itemCode=ITEM-001&page=0&size=10" -Headers $authHeaders
  if (@($balances.items).Count -lt 1) {
    throw "[FAIL] P0-F06 inventory balances returned empty."
  }
  $movements = Invoke-RestMethod -Method Get -Uri "$GatewayBaseUrl/api/inventory/v1/movements?itemCode=ITEM-001&page=0&size=10" -Headers $authHeaders
  if (@($movements.items).Count -lt 1) {
    throw "[FAIL] P0-F06 inventory movements returned empty."
  }
  Write-Host "[OK] P0-F06 inventory balances/movements passed."

  $reportCreate = Invoke-RestMethod -Method Post -Uri "$GatewayBaseUrl/api/report/v1/jobs" -Headers $authHeaders -ContentType "application/json" -Body (@{
    reportType = "P0_DAILY"
    requestedByMemberId = "smoke-user"
  } | ConvertTo-Json)
  $jobId = "$($reportCreate.jobId)"
  Assert-NotEmpty -Name "jobId" -Value $jobId
  $reportDetail = Invoke-RestMethod -Method Get -Uri "$GatewayBaseUrl/api/report/v1/jobs/$jobId" -Headers $authHeaders
  if ("$($reportDetail.jobId)" -ne $jobId) {
    throw "[FAIL] P0-F07 report detail mismatch."
  }
  Write-Host "[OK] P0-F07 report create/get passed."

  Write-Host "[OK] P0-F01~F07 gateway E2E smoke passed."
}
finally {
  Pop-Location
}
