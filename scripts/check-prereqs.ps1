param(
  [switch]$Strict
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$lockPath = Join-Path $repoRoot "toolchain.lock.json"

if (-not (Test-Path $lockPath)) {
  throw "toolchain.lock.json not found: $lockPath"
}

$lock = Get-Content -Raw -Encoding UTF8 $lockPath | ConvertFrom-Json

function Get-CommandLineOutput {
  param(
    [Parameter(Mandatory = $true)][string]$Executable,
    [string[]]$Arguments = @()
  )

  if (-not (Get-Command $Executable -ErrorAction SilentlyContinue)) {
    return @()
  }

  $escapedArgs = $Arguments | ForEach-Object {
    if ($_ -match "\s") { '"' + $_ + '"' } else { $_ }
  }
  $argLine = ($escapedArgs -join " ").Trim()
  $cmdLine = if ([string]::IsNullOrWhiteSpace($argLine)) { $Executable } else { "$Executable $argLine" }
  $output = cmd /c "$cmdLine 2>&1"
  return @($output)
}

function Extract-SemVer {
  param(
    [Parameter(Mandatory = $true)][string]$Text
  )

  if ($Text -match "(\d+\.\d+\.\d+)") {
    return $Matches[1]
  }
  if ($Text -match "(\d+\.\d+)") {
    return $Matches[1]
  }
  if ($Text -match "(\d+)") {
    return $Matches[1]
  }
  return $null
}

function Write-Result {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Actual,
    [Parameter(Mandatory = $true)][string]$Expected,
    [Parameter(Mandatory = $true)][bool]$Matched
  )

  if ($Matched) {
    Write-Host ("[OK]   {0,-15} actual={1,-15} expected={2}" -f $Name, $Actual, $Expected)
  }
  else {
    Write-Host ("[WARN] {0,-15} actual={1,-15} expected={2}" -f $Name, $Actual, $Expected)
  }
}

function StartsWithVersion {
  param(
    [string]$Actual,
    [string]$Expected
  )

  if ([string]::IsNullOrWhiteSpace($Actual)) {
    return $false
  }
  return $Actual.StartsWith($Expected)
}

$failCount = 0

Write-Host "Checking TO-BE development prerequisites against toolchain.lock.json..."
Write-Host "Lock file: $lockPath"
Write-Host ""

$dockerLine = (Get-CommandLineOutput -Executable "docker" -Arguments @("--version") | Select-Object -First 1)
$dockerComposeLine = (Get-CommandLineOutput -Executable "docker" -Arguments @("compose", "version") | Select-Object -First 1)
$nodeLine = (Get-CommandLineOutput -Executable "node" -Arguments @("-v") | Select-Object -First 1)
$pnpmLine = (Get-CommandLineOutput -Executable "pnpm" -Arguments @("--version") | Select-Object -First 1)
if ([string]::IsNullOrWhiteSpace([string]$pnpmLine)) {
  $pnpmLine = (Get-CommandLineOutput -Executable "corepack" -Arguments @("pnpm", "--version") | Select-Object -First 1)
}
$lockedGradleExe = Join-Path $env:USERPROFILE "tools\\gradle-$($lock.gradle)\\bin\\gradle.bat"
if (Test-Path $lockedGradleExe) {
  $gradleLine = (Get-CommandLineOutput -Executable $lockedGradleExe -Arguments @("-v") | Where-Object { [string]$_ -match "Gradle" } | Select-Object -First 1)
}
else {
  $gradleLine = (Get-CommandLineOutput -Executable "gradle" -Arguments @("-v") | Where-Object { [string]$_ -match "Gradle" } | Select-Object -First 1)
}

$userJavaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "User")
$javaLine = $null
if (-not [string]::IsNullOrWhiteSpace($userJavaHome)) {
  $userJavaExe = Join-Path $userJavaHome "bin\\java.exe"
  if (Test-Path $userJavaExe) {
    $javaLine = (Get-CommandLineOutput -Executable $userJavaExe -Arguments @("-version") | Where-Object { [string]$_ -match "version" } | Select-Object -First 1)
  }
}
if (-not $javaLine) {
  $javaLine = (Get-CommandLineOutput -Executable "java" -Arguments @("-version") | Where-Object { [string]$_ -match "version" } | Select-Object -First 1)
}

$dockerComposeVersion = Extract-SemVer -Text ([string]$dockerComposeLine)
$javaVersion = Extract-SemVer -Text ([string]$javaLine)
$nodeVersion = Extract-SemVer -Text ([string]$nodeLine)
$pnpmVersion = Extract-SemVer -Text ([string]$pnpmLine)
$gradleVersion = Extract-SemVer -Text ([string]$gradleLine)

$javaOk = StartsWithVersion -Actual $javaVersion -Expected ([string]$lock.java)
$nodeOk = StartsWithVersion -Actual $nodeVersion -Expected ([string]$lock.node)
$pnpmExpected = [string]$lock.pnpm
$pnpmPolicyEnabled = -not [string]::IsNullOrWhiteSpace($pnpmExpected)
$pnpmOk = $true
if ($pnpmPolicyEnabled) {
  $pnpmOk = StartsWithVersion -Actual $pnpmVersion -Expected $pnpmExpected
}
$gradleOk = StartsWithVersion -Actual $gradleVersion -Expected ([string]$lock.gradle)
$dockerComposeOk = StartsWithVersion -Actual $dockerComposeVersion -Expected ([string]$lock.docker_compose)

Write-Result -Name "Java" -Actual ([string]$javaVersion) -Expected ([string]$lock.java) -Matched $javaOk
if (-not $javaOk) { $failCount++ }

Write-Result -Name "Node.js" -Actual ([string]$nodeVersion) -Expected ([string]$lock.node) -Matched $nodeOk
if (-not $nodeOk) { $failCount++ }

if ($pnpmPolicyEnabled) {
  Write-Result -Name "pnpm" -Actual ([string]$pnpmVersion) -Expected $pnpmExpected -Matched $pnpmOk
  if (-not $pnpmOk) { $failCount++ }
}

Write-Result -Name "Gradle" -Actual ([string]$gradleVersion) -Expected ([string]$lock.gradle) -Matched $gradleOk
if (-not $gradleOk) { $failCount++ }

Write-Result -Name "DockerCompose" -Actual ([string]$dockerComposeVersion) -Expected ([string]$lock.docker_compose) -Matched $dockerComposeOk
if (-not $dockerComposeOk) { $failCount++ }

Write-Host ""
Write-Host "Detected JAVA_HOME(User): $userJavaHome"
Write-Host "Detected java -version line: $javaLine"
if (Test-Path $lockedGradleExe) {
  Write-Host "Detected locked gradle executable: $lockedGradleExe"
}
Write-Host ""

if ($Strict -and $failCount -gt 0) {
  throw "Prerequisite check failed with $failCount mismatch(es)."
}

if ($failCount -gt 0) {
  Write-Host ("[INFO] Completed with {0} mismatch(es). Use scripts\\use-toolchain.ps1 and align local installations." -f $failCount)
}
else {
  Write-Host "[INFO] All toolchain versions match the lock policy."
}
