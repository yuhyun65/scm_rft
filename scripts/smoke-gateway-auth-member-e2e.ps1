[CmdletBinding()]
param(
  [string]$GatewayBaseUrl = "http://localhost:18080",
  [string]$AuthHealthUrl = "http://localhost:8081/actuator/health",
  [string]$MemberHealthUrl = "http://localhost:8082/actuator/health",
  [string]$GatewayHealthUrl = "http://localhost:18080/actuator/health",
  [string]$Database = "MES_HI",
  [string]$SqlContainerName = "scm-sqlserver",
  [string]$EnvFile = ".env",
  [string]$LoginId = "smoke-user",
  [string]$Password = "password",
  [bool]$SeedData = $true
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$seedPasswordHash = '$2a$10$dFSWpkXBf.JGLtCo6ZeHoOrLGzptkVbtfb7hJ2K4SvdWk3kctTOY6'

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
    throw "[FAIL] $Name health check failed at $Uri. Ensure service is running."
  }
}

function Assert-ExpectedStatusCode {
  param(
    [Parameter(Mandatory = $true)][scriptblock]$Action,
    [Parameter(Mandatory = $true)][int]$ExpectedStatusCode,
    [Parameter(Mandatory = $true)][string]$Scenario
  )

  try {
    & $Action | Out-Null
    throw "[FAIL] $Scenario expected HTTP $ExpectedStatusCode but request succeeded."
  }
  catch {
    $statusCode = $null
    if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
      $statusCode = [int]$_.Exception.Response.StatusCode
    }
    if ($statusCode -ne $ExpectedStatusCode) {
      throw "[FAIL] $Scenario expected HTTP $ExpectedStatusCode but got $statusCode."
    }
    Write-Host ("[OK] {0}: HTTP {1}" -f $Scenario, $ExpectedStatusCode)
  }
}

function Seed-SmokeData {
  param(
    [Parameter(Mandatory = $true)][string]$RepoRoot,
    [Parameter(Mandatory = $true)][string]$ContainerName,
    [Parameter(Mandatory = $true)][string]$TargetDatabase,
    [Parameter(Mandatory = $true)][string]$TargetEnvFile,
    [Parameter(Mandatory = $true)][string]$PasswordHash
  )

  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "[FAIL] docker command not found. Disable seeding (-SeedData:`$false) or install Docker."
  }

  cmd /c "docker info >nul 2>nul"
  if ($LASTEXITCODE -ne 0) {
    throw "[FAIL] docker daemon is not running. Disable seeding (-SeedData:`$false) or start Docker Desktop."
  }

  $runningContainers = docker ps --format "{{.Names}}"
  if (($runningContainers | Where-Object { $_ -eq $ContainerName }).Count -eq 0) {
    throw "[FAIL] SQL container '$ContainerName' is not running. Disable seeding (-SeedData:`$false) or start the container."
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
    throw "[FAIL] seed data failed."
  }

  Write-Host "[OK] smoke seed data upsert completed."
}

Push-Location $repoRoot
try {
  Assert-Health -Name "auth" -Uri $AuthHealthUrl
  Assert-Health -Name "member" -Uri $MemberHealthUrl
  Assert-Health -Name "gateway" -Uri $GatewayHealthUrl

  if ($SeedData) {
    Seed-SmokeData -RepoRoot $repoRoot -ContainerName $SqlContainerName -TargetDatabase $Database -TargetEnvFile $EnvFile -PasswordHash $seedPasswordHash
  }
  else {
    Write-Host "[INFO] seed data skipped by option."
  }

  $loginUri = "$GatewayBaseUrl/api/auth/v1/login"
  $verifyUri = "$GatewayBaseUrl/api/auth/v1/tokens/verify"
  $memberSearchUri = "$GatewayBaseUrl/api/member/v1/members?status=ACTIVE&keyword=smoke&page=0&size=10"
  $memberByIdUri = "$GatewayBaseUrl/api/member/v1/members/$LoginId"

  try {
    $loginResponse = Invoke-RestMethod -Method Post -Uri $loginUri -ContentType "application/json" -Body (@{
      loginId = $LoginId
      password = $Password
    } | ConvertTo-Json)
  }
  catch {
    $statusCode = "unknown"
    if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
      $statusCode = [int]$_.Exception.Response.StatusCode
    }
    throw "[FAIL] login via gateway failed (HTTP $statusCode). Ensure auth/member are running with shared SQL configuration and credentials are seeded."
  }

  if (-not $loginResponse.accessToken) {
    throw "[FAIL] login succeeded but accessToken is empty."
  }
  Write-Host "[OK] login via gateway succeeded."

  $verifyResponse = Invoke-RestMethod -Method Post -Uri $verifyUri -ContentType "application/json" -Body (@{
    accessToken = "$($loginResponse.accessToken)"
  } | ConvertTo-Json)
  if (-not $verifyResponse.active) {
    throw "[FAIL] token verify returned inactive."
  }
  Write-Host "[OK] token verify via gateway succeeded."

  $authHeaders = @{ Authorization = "Bearer $($loginResponse.accessToken)" }

  $memberSearchResponse = Invoke-RestMethod -Method Get -Uri $memberSearchUri -Headers $authHeaders
  if ($memberSearchResponse.total -lt 1 -or @($memberSearchResponse.items).Count -lt 1) {
    throw "[FAIL] member search returned empty result."
  }
  Write-Host ("[OK] member search via gateway succeeded. total={0}" -f $memberSearchResponse.total)

  $memberByIdResponse = Invoke-RestMethod -Method Get -Uri $memberByIdUri -Headers $authHeaders
  if ("$($memberByIdResponse.memberId)" -ne $LoginId) {
    throw "[FAIL] member by id returned unexpected memberId."
  }
  Write-Host "[OK] member by id via gateway succeeded."

  Assert-ExpectedStatusCode -Scenario "member search without token" -ExpectedStatusCode 401 -Action {
    Invoke-WebRequest -Method Get -Uri $memberSearchUri -UseBasicParsing | Out-Null
  }

  Assert-ExpectedStatusCode -Scenario "member search with invalid token" -ExpectedStatusCode 401 -Action {
    Invoke-WebRequest -Method Get -Uri $memberSearchUri -Headers @{ Authorization = "Bearer invalid-token" } -UseBasicParsing | Out-Null
  }

  Write-Host "[OK] gateway auth/member E2E smoke passed."
}
finally {
  Pop-Location
}
