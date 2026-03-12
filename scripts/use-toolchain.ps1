param(
  [switch]$Persist
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$lockPath = Join-Path $repoRoot "toolchain.lock.json"

if (-not (Test-Path $lockPath)) {
  throw "toolchain.lock.json not found: $lockPath"
}

$lock = Get-Content -Raw -Encoding UTF8 $lockPath | ConvertFrom-Json

$jdkHome = $null
$jdkCandidates = @()

$userJavaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "User")
if (-not [string]::IsNullOrWhiteSpace($userJavaHome) -and (Test-Path $userJavaHome)) {
  $jdkCandidates += $userJavaHome
}

$defaultJdkBase = Join-Path $env:USERPROFILE ".jdks"
if (Test-Path $defaultJdkBase) {
  $jdkCandidates += (Get-ChildItem $defaultJdkBase -Directory | Where-Object { $_.Name -like "jdk-21*" } | Sort-Object LastWriteTime -Descending | Select-Object -ExpandProperty FullName)
}

$jdkHome = $jdkCandidates | Select-Object -First 1
if ([string]::IsNullOrWhiteSpace($jdkHome)) {
  throw "JDK 21 not found. Install Java 21 first."
}

$javaBin = Join-Path $jdkHome "bin"
$env:JAVA_HOME = $jdkHome
if ($env:Path -notlike "*$javaBin*") {
  $env:Path = "$javaBin;$env:Path"
}

$gradleBin = Join-Path $env:USERPROFILE "tools\\gradle-$($lock.gradle)\\bin"
if (Test-Path $gradleBin) {
  if ($env:Path -notlike "*$gradleBin*") {
    $env:Path = "$gradleBin;$env:Path"
  }
}

if ($Persist) {
  [Environment]::SetEnvironmentVariable("JAVA_HOME", $jdkHome, "User")
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")

  if ((Test-Path $gradleBin) -and ($userPath -notlike "*$gradleBin*")) {
    if ([string]::IsNullOrWhiteSpace($userPath)) {
      $userPath = $gradleBin
    }
    else {
      $userPath = "$gradleBin;$userPath"
    }
  }

  if ([string]::IsNullOrWhiteSpace($userPath)) {
    $newUserPath = $javaBin
  }
  elseif ($userPath -notlike "*$javaBin*") {
    $newUserPath = "$javaBin;$userPath"
  }
  else {
    $newUserPath = $userPath
  }
  [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
}

Write-Host "Toolchain applied for current session."
Write-Host "JAVA_HOME=$env:JAVA_HOME"
Write-Host "java -version:"
& (Join-Path $env:JAVA_HOME "bin\\java.exe") -version

if (-not [string]::IsNullOrWhiteSpace([string]$lock.pnpm)) {
  if (Get-Command corepack -ErrorAction SilentlyContinue) {
    & corepack prepare ("pnpm@{0}" -f [string]$lock.pnpm) --activate
    if ($LASTEXITCODE -eq 0) {
      Write-Host "pnpm policy applied via corepack: $($lock.pnpm)"
    }
    else {
      Write-Host "[WARN] corepack prepare pnpm failed. Check network/permissions."
    }
  }
  else {
    Write-Host "[WARN] corepack not found. pnpm policy cannot be auto-applied."
  }
}

Write-Host ""
Write-Host "Policy lock:"
Write-Host "- Java: $($lock.java)"
Write-Host "- Node: $($lock.node)"
if (-not [string]::IsNullOrWhiteSpace([string]$lock.pnpm)) {
  Write-Host "- pnpm: $($lock.pnpm)"
}
Write-Host "- Gradle: $($lock.gradle)"
Write-Host "- Docker Compose: $($lock.docker_compose)"
