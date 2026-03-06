param(
  [string]$EnvFile = ".env.production"
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$envPath = Join-Path $repoRoot $EnvFile

if (-not (Test-Path $envPath)) {
  throw "[FAIL] env file not found: $envPath"
}

$requiredKeys = @(
  "SCM_DB_URL",
  "SCM_DB_USER",
  "SCM_DB_PASSWORD",
  "SCM_DB_DRIVER",
  "SCM_FLYWAY_ENABLED",
  "SCM_FLYWAY_LOCATIONS",
  "SCM_FLYWAY_TABLE",
  "SCM_AUTH_JWT_SECRET",
  "SCM_AUTH_JWT_ISSUER",
  "SCM_AUTH_ACCESS_TOKEN_EXP_SECONDS",
  "SCM_AUTH_LOGIN_MAX_FAILED_ATTEMPTS",
  "SCM_AUTH_LOGIN_LOCK_MINUTES",
  "BOARD_FILE_SERVICE_BASE_URL",
  "GATEWAY_POLICY_PATH",
  "GATEWAY_AUTH_VERIFY_URI",
  "GATEWAY_AUTH_VERIFY_TIMEOUT_MS",
  "GATEWAY_AUTH_CB_SLIDING_WINDOW_SIZE",
  "GATEWAY_AUTH_CB_MIN_CALLS",
  "GATEWAY_AUTH_CB_FAILURE_RATE_THRESHOLD",
  "GATEWAY_AUTH_CB_WAIT_OPEN_MS",
  "GATEWAY_AUTH_CB_HALF_OPEN_CALLS",
  "GATEWAY_EMERGENCY_STOP_ENABLED",
  "GATEWAY_EMERGENCY_STOP_STATUS"
)

$blockedValues = @(
  "scm-rft-default-jwt-secret-key-change-me-2026",
  "YourStrong!Passw0rd",
  "admin",
  "scm1234",
  "scm_stage_1234",
  "<REQUIRED_STRONG_PASSWORD>",
  "<REQUIRED_RANDOM_SECRET_MIN_32_CHARS>"
)

function Parse-EnvFile {
  param([string]$Path)

  $map = @{}
  $lines = Get-Content -Encoding UTF8 $Path
  foreach ($line in $lines) {
    $trimmed = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
    if ($trimmed.StartsWith("#")) { continue }
    $parts = $trimmed.Split("=", 2)
    if ($parts.Count -ne 2) { continue }
    $key = $parts[0].Trim()
    $val = $parts[1].Trim()
    $map[$key] = $val
  }
  return $map
}

$kv = Parse-EnvFile -Path $envPath
$failures = [System.Collections.Generic.List[string]]::new()

foreach ($key in $requiredKeys) {
  if (-not $kv.ContainsKey($key)) {
    $failures.Add("missing key: $key")
    continue
  }
  $value = $kv[$key]
  if ([string]::IsNullOrWhiteSpace($value)) {
    $failures.Add("blank value: $key")
    continue
  }

  foreach ($blocked in $blockedValues) {
    if ($value -eq $blocked) {
      $failures.Add("blocked default value: $key")
      break
    }
  }

  if ($value -match "^<.*>$") {
    $failures.Add("placeholder not replaced: $key")
  }
}

$jwt = $kv["SCM_AUTH_JWT_SECRET"]
if (-not [string]::IsNullOrWhiteSpace($jwt) -and $jwt.Length -lt 32) {
  $failures.Add("SCM_AUTH_JWT_SECRET length must be >= 32")
}

$trackedEnvProduction = git -C $repoRoot ls-files .env.production | Out-String
if (-not [string]::IsNullOrWhiteSpace($trackedEnvProduction.Trim())) {
  $failures.Add(".env.production must not be tracked")
}

if ($failures.Count -gt 0) {
  Write-Host "[FAIL] production secret precheck failed."
  $failures | ForEach-Object { Write-Host (" - " + $_) }
  exit 1
}

Write-Host "[OK] production secret precheck passed."
Write-Host ("[OK] checked keys: {0}" -f $requiredKeys.Count)
