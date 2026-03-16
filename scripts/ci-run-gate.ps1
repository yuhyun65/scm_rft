param(
  [Parameter(Mandatory = $true)][ValidateSet("build", "unit-integration-test", "contract-test", "lint-static-analysis", "security-scan", "migration-dry-run", "smoke-test", "frontend-build", "frontend-unit-test", "frontend-contract-test", "frontend-e2e-smoke", "frontend-security-scan")][string]$Gate
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$script:GradleUserHomeReady = $false
$script:FrontendDepsReady = $false

function Ensure-ToolchainSession {
  if ($env:SCM_TOOLCHAIN_READY -eq "1") {
    return
  }

  $toolchainScript = Join-Path $PSScriptRoot "use-toolchain.ps1"
  if (-not (Test-Path $toolchainScript)) {
    throw "[FAIL] toolchain bootstrap script not found: scripts/use-toolchain.ps1"
  }

  Write-Host "[INFO] Applying toolchain lock policy for this gate run..."
  & $toolchainScript
  if ($LASTEXITCODE -ne 0) {
    throw "[FAIL] toolchain bootstrap failed."
  }
  $env:SCM_TOOLCHAIN_READY = "1"
}

function Test-DirectoryWritable {
  param(
    [Parameter(Mandatory = $true)][string]$Path
  )

  try {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    $probe = Join-Path $Path (".write-probe-{0}.tmp" -f [guid]::NewGuid().ToString("N"))
    Set-Content -Path $probe -Value "probe" -Encoding UTF8 -ErrorAction Stop
    Remove-Item -Path $probe -Force -ErrorAction SilentlyContinue
    return $true
  }
  catch {
    return $false
  }
}

function Ensure-GradleUserHome {
  if ($script:GradleUserHomeReady) {
    return
  }

  $requested = $env:GRADLE_USER_HOME
  if (-not [string]::IsNullOrWhiteSpace($requested)) {
    $target = $requested
    try {
      $target = (Resolve-Path -Path $requested -ErrorAction Stop).Path
    }
    catch {
      # Keep raw path and attempt create/write test.
    }

    if (Test-DirectoryWritable -Path $target) {
      $env:GRADLE_USER_HOME = $target
      Write-Host ("[INFO] Gradle user home: {0}" -f $target)
      $script:GradleUserHomeReady = $true
      return
    }

    Write-Host ("[WARN] GRADLE_USER_HOME not writable: {0}" -f $requested)
  }

  $candidates = @()
  $userProfile = [Environment]::GetFolderPath("UserProfile")
  if (-not [string]::IsNullOrWhiteSpace($userProfile)) {
    $candidates += (Join-Path $userProfile ".gradle-scm-rft")
  }
  $candidates += (Join-Path $repoRoot ".gradle-user")

  foreach ($candidate in $candidates) {
    if (Test-DirectoryWritable -Path $candidate) {
      $env:GRADLE_USER_HOME = $candidate
      Write-Host ("[INFO] Gradle user home fallback applied: {0}" -f $candidate)
      $script:GradleUserHomeReady = $true
      return
    }
  }

  throw ("[FAIL] unable to prepare fallback GRADLE_USER_HOME. candidates={0}" -f ($candidates -join ", "))
}

function Get-GradleWrapper {
  if (Test-Path (Join-Path $repoRoot "gradlew.bat")) { return (Join-Path $repoRoot "gradlew.bat") }
  if (Test-Path (Join-Path $repoRoot "gradlew")) { return (Join-Path $repoRoot "gradlew") }
  return $null
}

function Get-LocalGradleExecutable {
  $lockFile = Join-Path $repoRoot "toolchain.lock.json"
  $version = ""
  if (Test-Path $lockFile) {
    try {
      $lock = Get-Content -Raw -Encoding UTF8 $lockFile | ConvertFrom-Json
      if ($lock.gradle) {
        $version = [string]$lock.gradle
      }
    }
    catch {
      # Fall back to command discovery below.
    }
  }

  $candidates = @()
  $userProfile = [Environment]::GetFolderPath("UserProfile")
  if (-not [string]::IsNullOrWhiteSpace($version) -and -not [string]::IsNullOrWhiteSpace($userProfile)) {
    $candidates += (Join-Path $userProfile ("tools\gradle-{0}\bin\gradle.bat" -f $version))
  }
  $candidates += "gradle"

  foreach ($candidate in $candidates) {
    if ($candidate -eq "gradle") {
      if (Get-Command gradle -ErrorAction SilentlyContinue) {
        return "gradle"
      }
      continue
    }

    if (Test-Path $candidate) {
      return $candidate
    }
  }

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

  Ensure-GradleUserHome
  $gradleArgs = @($Arguments)
  if ($gradleArgs -notcontains "--no-daemon") {
    $gradleArgs += "--no-daemon"
  }

  if ($wrapper) {
    Write-Host ("[INFO] {0}: running {1} {2}" -f $GateName, $wrapper, ($gradleArgs -join " "))
    & $wrapper @gradleArgs
    if ($LASTEXITCODE -eq 0) {
      return
    }
    Write-Warning ("wrapper gradle invocation failed for {0}; attempting local Gradle fallback." -f $GateName)
  }

  $localGradle = Get-LocalGradleExecutable
  if (-not $localGradle) {
    throw "[FAIL] ${GateName}: gradle command failed and no local fallback was found."
  }

  Write-Host ("[INFO] {0}: running fallback {1} {2}" -f $GateName, $localGradle, ($gradleArgs -join " "))
  & $localGradle @gradleArgs
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
  $matches = & rg --line-number --hidden `
    --glob "!.git/**" `
    --glob "!.gradle/**" `
    --glob "!.gradle-user/**" `
    --glob "!.tmp/**" `
    --glob "!build/**" `
    --glob "!services/*/build/**" `
    --glob "!services/*/bin/**" `
    --glob "!runbooks/evidence/**" `
    --glob "!HISCM/**" `
    $pattern $repoRoot

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

function Get-FrontendRoot {
  return (Join-Path $repoRoot "frontend")
}

function Get-PnpmCommand {
  if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    return @("pnpm")
  }
  if (Get-Command corepack -ErrorAction SilentlyContinue) {
    return @("corepack", "pnpm")
  }
  throw "[FAIL] frontend gate: pnpm/corepack not found. Install Node 22 and enable corepack."
}

function Initialize-FrontendDependencies {
  if ($script:FrontendDepsReady) {
    return
  }

  $frontendRoot = Get-FrontendRoot
  if (-not (Test-Path $frontendRoot)) {
    throw "[FAIL] frontend gate: frontend workspace not found."
  }

  $toolchainLock = Join-Path $repoRoot "toolchain.lock.json"
  if ((Get-Command corepack -ErrorAction SilentlyContinue) -and (Test-Path $toolchainLock)) {
    $lock = Get-Content -Raw -Encoding UTF8 $toolchainLock | ConvertFrom-Json
    if (-not [string]::IsNullOrWhiteSpace([string]$lock.pnpm)) {
      & corepack prepare ("pnpm@{0}" -f [string]$lock.pnpm) --activate
      if ($LASTEXITCODE -ne 0) {
        throw "[FAIL] frontend gate: corepack prepare pnpm failed."
      }
    }
  }

  $pnpmCommand = Get-PnpmCommand
  $pnpmExec = $pnpmCommand[0]
  $pnpmPrefix = @()
  if ($pnpmCommand.Count -gt 1) {
    $pnpmPrefix += $pnpmCommand[1..($pnpmCommand.Count - 1)]
  }

  $lockFile = Join-Path $frontendRoot "pnpm-lock.yaml"
  $installArgs = @()
  if (Test-Path $lockFile) {
    $installArgs = @("-C", $frontendRoot, "install", "--frozen-lockfile")
  }
  else {
    $installArgs = @("-C", $frontendRoot, "install")
  }

  $installInvocation = $pnpmPrefix + $installArgs
  Write-Host ("[INFO] frontend dependencies: {0} {1}" -f $pnpmExec, ($installInvocation -join " "))
  & $pnpmExec @installInvocation
  if ($LASTEXITCODE -ne 0) {
    throw "[FAIL] frontend gate: dependency install failed."
  }

  $script:FrontendDepsReady = $true
}

function Invoke-FrontendGate {
  param(
    [Parameter(Mandatory = $true)][string[]]$Arguments,
    [Parameter(Mandatory = $true)][string]$GateName
  )

  Initialize-FrontendDependencies

  $frontendRoot = Get-FrontendRoot
  $pnpmCommand = Get-PnpmCommand
  $pnpmExec = $pnpmCommand[0]
  $pnpmPrefix = @()
  if ($pnpmCommand.Count -gt 1) {
    $pnpmPrefix += $pnpmCommand[1..($pnpmCommand.Count - 1)]
  }

  $invocationArgs = $pnpmPrefix + @("-C", $frontendRoot) + $Arguments
  Write-Host ("[INFO] {0}: running {1} {2}" -f $GateName, $pnpmExec, ($invocationArgs -join " "))
  & $pnpmExec @invocationArgs
  if ($LASTEXITCODE -ne 0) {
    throw "[FAIL] ${GateName}: frontend command failed."
  }
}

function Invoke-FrontendSecurityScan {
  $frontendRoot = Get-FrontendRoot
  if (-not (Test-Path $frontendRoot)) {
    throw "[FAIL] frontend-security-scan: frontend workspace not found."
  }

  if (-not (Get-Command rg -ErrorAction SilentlyContinue)) {
    Write-Host "[SKIP] frontend-security-scan: rg not found."
    return
  }

  $pattern = "(AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{20,}|-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----)"
  $matches = & rg --line-number --hidden --glob "!**/node_modules/**" --glob "!**/dist/**" $pattern $frontendRoot

  if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace(($matches -join ""))) {
    Write-Host $matches
    throw "[FAIL] frontend-security-scan: potential secret patterns found."
  }
  if ($LASTEXITCODE -gt 1) {
    throw "[FAIL] frontend-security-scan: rg execution error."
  }

  Write-Host "[OK] frontend-security-scan: no obvious secret pattern detected."
}

Push-Location $repoRoot
try {
  Ensure-ToolchainSession
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
    "frontend-build" {
      Invoke-FrontendGate -Arguments @("-r", "build") -GateName "frontend-build"
    }
    "frontend-unit-test" {
      Invoke-FrontendGate -Arguments @("-r", "test") -GateName "frontend-unit-test"
    }
    "frontend-contract-test" {
      Invoke-FrontendGate -Arguments @("--filter", "@scm-rft/api-client", "contract:generate") -GateName "frontend-contract-test"
    }
    "frontend-e2e-smoke" {
      Invoke-FrontendGate -Arguments @("--filter", "@scm-rft/web-portal", "e2e") -GateName "frontend-e2e-smoke"
    }
    "frontend-security-scan" {
      Invoke-FrontendSecurityScan
    }
  }
}
finally {
  Pop-Location
}
