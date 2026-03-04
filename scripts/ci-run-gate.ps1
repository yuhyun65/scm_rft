param(
  [Parameter(Mandatory = $true)][ValidateSet("build", "unit-integration-test", "contract-test", "lint-static-analysis", "security-scan", "migration-dry-run", "smoke-test")][string]$Gate
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

function Get-GradleWrapper {
  if (Test-Path (Join-Path $repoRoot "gradlew.bat")) { return (Join-Path $repoRoot "gradlew.bat") }
  if (Test-Path (Join-Path $repoRoot "gradlew")) { return (Join-Path $repoRoot "gradlew") }
  return $null
}

function Get-GradleBuildFiles {
  $targets = @("build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts")
  $files = @()
  foreach ($name in $targets) {
    $files += Get-ChildItem -Path $repoRoot -Recurse -File -Filter $name -ErrorAction SilentlyContinue | Where-Object {
      $_.FullName -notmatch "\\\.git\\" -and $_.FullName -notmatch "\\HISCM\\"
    }
  }
  return $files
}

function Invoke-GradleGate {
  param(
    [Parameter(Mandatory = $true)][string[]]$Arguments,
    [Parameter(Mandatory = $true)][string]$GateName
  )

  $wrapper = Get-GradleWrapper
  $buildFiles = Get-GradleBuildFiles

  if (-not $wrapper) {
    if ($buildFiles.Count -gt 0) {
      throw "[FAIL] ${GateName}: Gradle build files found but wrapper missing."
    }
    Write-Host "[SKIP] ${GateName}: no Gradle project detected."
    return
  }

  Write-Host ("[INFO] {0}: running {1} {2}" -f $GateName, $wrapper, ($Arguments -join " "))
  & $wrapper @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "[FAIL] ${GateName}: gradle command failed."
  }
}

function Assert-OpenApiContracts {
  $contractsDir = Join-Path $repoRoot "shared/contracts"
  if (-not (Test-Path $contractsDir)) {
    Write-Host "[SKIP] contract-test: shared/contracts not found."
    return
  }

  $files = Get-ChildItem -Path $contractsDir -Recurse -File -Include *.openapi.yaml, *.openapi.yml -ErrorAction SilentlyContinue
  if ($files.Count -eq 0) {
    Write-Host "[SKIP] contract-test: no OpenAPI contract file found."
    return
  }

  foreach ($f in $files) {
    $content = Get-Content -Raw -Encoding UTF8 $f.FullName
    if ([string]::IsNullOrWhiteSpace($content)) {
      throw "[FAIL] contract-test: empty contract file $($f.FullName)"
    }
    if ($content -notmatch "(?m)^openapi:\s*3\.") {
      throw "[FAIL] contract-test: openapi version missing in $($f.FullName)"
    }
    if ($content -notmatch "(?m)^paths:") {
      throw "[FAIL] contract-test: paths section missing in $($f.FullName)"
    }
  }

  Write-Host ("[OK] contract-test: validated {0} contract file(s)." -f $files.Count)
}

function Invoke-SecretScan {
  $trackedEnvRaw = git -C $repoRoot ls-files .env
  $trackedEnv = ""
  if ($trackedEnvRaw) {
    $trackedEnv = ($trackedEnvRaw | Out-String).Trim()
  }
  if (-not [string]::IsNullOrWhiteSpace($trackedEnv)) {
    throw "[FAIL] security-scan: .env file must not be tracked."
  }

  if (-not (Get-Command rg -ErrorAction SilentlyContinue)) {
    Write-Host "[SKIP] security-scan: rg not found. pattern scan skipped."
    return
  }

  $pattern = "(AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{20,}|-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----)"
  $matches = & rg --line-number --hidden --glob "!.git/**" --glob "!HISCM/**" $pattern $repoRoot

  if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace(($matches -join ""))) {
    Write-Host $matches
    throw "[FAIL] security-scan: potential secret patterns found."
  }

  if ($LASTEXITCODE -gt 1) {
    throw "[FAIL] security-scan: rg execution error."
  }

  Write-Host "[OK] security-scan: no obvious secret pattern detected."
}

function Invoke-MigrationDryRun {
  $dryRun = Join-Path $repoRoot "migration/scripts/dry-run.ps1"
  if (-not (Test-Path $dryRun)) {
    Write-Host "[SKIP] migration-dry-run: migration/scripts/dry-run.ps1 not found."
    return
  }

  & powershell -ExecutionPolicy Bypass -File $dryRun
  if ($LASTEXITCODE -ne 0) {
    throw "[FAIL] migration-dry-run: dry-run script failed."
  }
}

function Invoke-SmokeTest {
  $composeFile = Join-Path $repoRoot "docker-compose.yml"
  if (Test-Path $composeFile) {
    cmd /c "docker compose -f `"$composeFile`" config >nul 2>nul"
    if ($LASTEXITCODE -ne 0) {
      throw "[FAIL] smoke-test: docker compose config failed."
    }
    Write-Host "[OK] smoke-test: docker compose config passed."
  }
  else {
    Write-Host "[SKIP] smoke-test: docker-compose.yml not found."
  }

  $agenticNewRun = Join-Path $repoRoot "scripts/agentic-new-run.ps1"
  $agenticValidate = Join-Path $repoRoot "scripts/agentic-validate-run.ps1"
  if ((Test-Path $agenticNewRun) -and (Test-Path $agenticValidate)) {
    $tempRoot = Join-Path $repoRoot ".agentic-ci-smoke"
    & powershell -ExecutionPolicy Bypass -File $agenticNewRun -IssueId CI-SMOKE -Service auth -RunId CI-SMOKE-RUN -OutputRoot $tempRoot
    if ($LASTEXITCODE -ne 0) { throw "[FAIL] smoke-test: agentic-new-run failed." }
    & powershell -ExecutionPolicy Bypass -File $agenticValidate -RunDir (Join-Path $tempRoot "CI-SMOKE-RUN")
    if ($LASTEXITCODE -ne 0) { throw "[FAIL] smoke-test: agentic-validate-run failed." }
    Remove-Item -Recurse -Force $tempRoot
    Write-Host "[OK] smoke-test: agentic run smoke passed."
  }
  else {
    Write-Host "[SKIP] smoke-test: agentic scripts not found."
  }

  $gatewayE2ESmoke = Join-Path $repoRoot "scripts/smoke-gateway-auth-member-e2e.ps1"
  if (-not (Test-Path $gatewayE2ESmoke)) {
    Write-Host "[SKIP] smoke-test: scripts/smoke-gateway-auth-member-e2e.ps1 not found."
    return
  }

  if ($env:SCM_ENABLE_GATEWAY_E2E_SMOKE -eq "1") {
    $smokeArgs = @()
    if (-not [string]::IsNullOrWhiteSpace($env:SCM_GATEWAY_BASE_URL)) {
      $smokeArgs += @("-GatewayBaseUrl", $env:SCM_GATEWAY_BASE_URL)
    }
    if (-not [string]::IsNullOrWhiteSpace($env:SCM_SQL_CONTAINER_NAME)) {
      $smokeArgs += @("-SqlContainerName", $env:SCM_SQL_CONTAINER_NAME)
    }
    if (-not [string]::IsNullOrWhiteSpace($env:SCM_ENV_FILE)) {
      $smokeArgs += @("-EnvFile", $env:SCM_ENV_FILE)
    }
    if (-not [string]::IsNullOrWhiteSpace($env:SCM_DB_NAME)) {
      $smokeArgs += @("-Database", $env:SCM_DB_NAME)
    }
    $smokePassed = $false
    $maxAttempts = 2
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
      & powershell -ExecutionPolicy Bypass -File $gatewayE2ESmoke @smokeArgs
      if ($LASTEXITCODE -eq 0) {
        $smokePassed = $true
        break
      }
      if ($attempt -lt $maxAttempts) {
        Write-Host "[WARN] smoke-test: gateway auth/member e2e failed. retrying once..."
        Start-Sleep -Seconds 1
      }
    }
    if (-not $smokePassed) {
      throw "[FAIL] smoke-test: gateway auth/member e2e smoke failed after retry."
    }
    Write-Host "[OK] smoke-test: gateway auth/member e2e smoke passed."
  }
  else {
    Write-Host "[SKIP] smoke-test: set SCM_ENABLE_GATEWAY_E2E_SMOKE=1 to run gateway auth/member e2e smoke."
  }
}

Push-Location $repoRoot
try {
  switch ($Gate) {
    "build" {
      Invoke-GradleGate -Arguments @("build", "-x", "test") -GateName "build"
    }
    "unit-integration-test" {
      Invoke-GradleGate -Arguments @("test") -GateName "unit-integration-test"
    }
    "contract-test" {
      Assert-OpenApiContracts
    }
    "lint-static-analysis" {
      Invoke-GradleGate -Arguments @("check") -GateName "lint-static-analysis"
    }
    "security-scan" {
      Invoke-SecretScan
    }
    "migration-dry-run" {
      Invoke-MigrationDryRun
    }
    "smoke-test" {
      Invoke-SmokeTest
    }
  }
}
finally {
  Pop-Location
}
