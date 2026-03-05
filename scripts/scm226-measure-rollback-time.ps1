param(
  [string]$RunId = "",
  [string]$Database = "MES_HI",
  [string]$ContainerName = "scm-sqlserver",
  [string]$EnvFile = ".env",
  [switch]$Staging,
  [string]$BackupFile = "",
  [switch]$SkipBackup,
  [int]$ThresholdMinutes = 20,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

if ([string]::IsNullOrWhiteSpace($RunId)) {
  $RunId = "SCM-226-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
}

if ($Staging) {
  if ([string]::IsNullOrWhiteSpace($ContainerName) -or $ContainerName -eq "scm-sqlserver") {
    $ContainerName = "scm-stg-sqlserver"
  }
  if ($EnvFile -eq ".env") {
    $EnvFile = ".env.staging"
  }
}

$evidenceDir = Join-Path $repoRoot ("runbooks/evidence/{0}" -f $RunId)
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null

function Invoke-LoggedPowerShell {
  param(
    [Parameter(Mandatory = $true)][string]$ArgumentLine,
    [Parameter(Mandatory = $true)][string]$LogPath
  )

  $errPath = "$LogPath.err"
  if (Test-Path $LogPath) { Remove-Item -Force $LogPath }
  if (Test-Path $errPath) { Remove-Item -Force $errPath }

  $proc = Start-Process -FilePath "powershell" -ArgumentList $ArgumentLine -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput $LogPath -RedirectStandardError $errPath

  if (Test-Path $errPath) {
    $err = Get-Content -Raw -Encoding UTF8 $errPath
    if (-not [string]::IsNullOrWhiteSpace($err)) {
      Add-Content -Path $LogPath -Value $err -Encoding UTF8
    }
    Remove-Item -Force $errPath
  }

  return $proc.ExitCode
}

$backupRoot = Join-Path $repoRoot "migration/backups"
if ($Staging) {
  $backupRoot = Join-Path $backupRoot "staging"
}
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

$backupLog = Join-Path $evidenceDir "backup.log"
$restoreLog = Join-Path $evidenceDir "rollback-restore.log"
$healthLog = Join-Path $evidenceDir "rollback-health.log"
$summaryMd = Join-Path $evidenceDir "rollback-time-summary.md"
$summaryJson = Join-Path $evidenceDir "rollback-time-summary.json"

if ([string]::IsNullOrWhiteSpace($BackupFile)) {
  if (-not $SkipBackup) {
    $backupScript = Join-Path $repoRoot "scripts/backup-db.ps1"
    $backupArg = "-ExecutionPolicy Bypass -File `"{0}`" -Database `"{1}`" -ContainerName `"{2}`" -EnvFile `"{3}`"" -f $backupScript, $Database, $ContainerName, $EnvFile
    if ($Staging) {
      $backupArg += " -Staging"
    }
    if ($DryRun) {
      "[DRYRUN] powershell $backupArg" | Set-Content -Encoding UTF8 $backupLog
    }
    else {
      $backupExit = Invoke-LoggedPowerShell -ArgumentLine $backupArg -LogPath $backupLog
      if ($backupExit -ne 0) {
        throw "backup failed. check $backupLog"
      }
    }
  }

  if ($DryRun) {
    $BackupFile = "$($Database)_DRYRUN.bak"
  }
  else {
    $latest = Get-ChildItem -Path $backupRoot -Filter "$($Database)_*.bak" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) {
      throw "no backup file found under $backupRoot"
    }
    $BackupFile = $latest.Name
  }
}
else {
  $BackupFile = Split-Path -Path $BackupFile -Leaf
}

$backupPath = Join-Path $backupRoot $BackupFile
if (-not $DryRun -and -not (Test-Path $backupPath)) {
  throw "backup file not found: $backupPath"
}

$restoreScript = Join-Path $repoRoot "scripts/restore-db.ps1"
$restoreArg = "-ExecutionPolicy Bypass -File `"{0}`" -BackupFile `"{1}`" -Database `"{2}`" -ContainerName `"{3}`" -EnvFile `"{4}`"" -f $restoreScript, $BackupFile, $Database, $ContainerName, $EnvFile
if ($Staging) {
  $restoreArg += " -Staging"
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()
if ($DryRun) {
  "[DRYRUN] powershell $restoreArg" | Set-Content -Encoding UTF8 $restoreLog
  Start-Sleep -Milliseconds 200
  $restoreExit = 0
}
else {
  $restoreExit = Invoke-LoggedPowerShell -ArgumentLine $restoreArg -LogPath $restoreLog
}
$sw.Stop()

$elapsedSec = [Math]::Round($sw.Elapsed.TotalSeconds, 2)
$elapsedMin = [Math]::Round($sw.Elapsed.TotalMinutes, 2)
$thresholdSec = $ThresholdMinutes * 60
$withinThreshold = ($elapsedSec -le $thresholdSec)
$restoreSucceeded = ($restoreExit -eq 0)
$verdict = if ($DryRun) { "DRYRUN" } elseif ($restoreSucceeded -and $withinThreshold) { "PASS" } else { "FAIL" }

$healthRows = @()
$healthUris = @(
  "http://localhost:8081/actuator/health",
  "http://localhost:8082/actuator/health",
  "http://localhost:18080/actuator/health"
)

foreach ($uri in $healthUris) {
  if ($DryRun) {
    $healthRows += [pscustomobject]@{ Uri = $uri; Status = "SKIPPED"; Result = "SKIPPED" }
  }
  else {
    try {
      $resp = Invoke-RestMethod -Uri $uri -TimeoutSec 3
      $status = if ($resp.status) { $resp.status } else { "UNKNOWN" }
      $healthRows += [pscustomobject]@{ Uri = $uri; Status = $status; Result = "PASS" }
    }
    catch {
      $healthRows += [pscustomobject]@{ Uri = $uri; Status = "DOWN"; Result = "FAIL" }
    }
  }
}

$healthRows | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 $healthLog

$summary = [pscustomobject]@{
  runId = $RunId
  generatedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
  database = $Database
  staging = [bool]$Staging
  backupFile = $BackupFile
  backupPath = $backupPath
  restoreExitCode = $restoreExit
  restoreSucceeded = $restoreSucceeded
  elapsedSeconds = $elapsedSec
  elapsedMinutes = $elapsedMin
  thresholdMinutes = $ThresholdMinutes
  withinThreshold = $withinThreshold
  verdict = $verdict
  logs = [pscustomobject]@{
    backup = $(if (Test-Path $backupLog) { $backupLog } else { "" })
    restore = $restoreLog
    health = $healthLog
  }
}

$summary | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $summaryJson

$md = @()
$md += "# SCM-226 Rollback Time Summary"
$md += ""
$md += "- RunId: $RunId"
$md += "- GeneratedAt: $($summary.generatedAt)"
$md += "- Database: $Database"
$md += "- BackupFile: $BackupFile"
$md += "- RestoreExitCode: $restoreExit"
$md += "- ElapsedMinutes: $elapsedMin"
$md += "- ThresholdMinutes: $ThresholdMinutes"
$md += "- Verdict: $verdict"
$md += ""
$md += "## DoD"
$md += "| Check | Value | Result |"
$md += "|---|---:|---|"
$md += ("| Restore success | {0} | {1} |" -f $restoreSucceeded, $(if ($restoreSucceeded) { "PASS" } else { "FAIL" }))
$md += ("| Rollback time <= {0} min | {1} min | {2} |" -f $ThresholdMinutes, $elapsedMin, $(if ($withinThreshold) { "PASS" } else { "FAIL" }))
$md += ""
$md += "## Evidence"
$md += "- Restore log: runbooks/evidence/$RunId/rollback-restore.log"
if (Test-Path $backupLog) {
  $md += "- Backup log: runbooks/evidence/$RunId/backup.log"
}
$md += "- Health log: runbooks/evidence/$RunId/rollback-health.log"
$md += "- Summary JSON: runbooks/evidence/$RunId/rollback-time-summary.json"
$md += ""
$md += "## Health Check"
$md += "| Uri | Status | Result |"
$md += "|---|---|---|"
foreach ($h in $healthRows) {
  $md += ("| {0} | {1} | {2} |" -f $h.Uri, $h.Status, $h.Result)
}

$md -join [Environment]::NewLine | Set-Content -Encoding UTF8 $summaryMd

Write-Host "[OK] rollback-time summary generated: $summaryMd"
Write-Host "[INFO] elapsedMinutes=$elapsedMin thresholdMinutes=$ThresholdMinutes verdict=$verdict"

if ($DryRun) {
  return
}

if (-not $restoreSucceeded) {
  throw "restore failed. check $restoreLog"
}
if (-not $withinThreshold) {
  throw "rollback threshold exceeded: $elapsedMin min > $ThresholdMinutes min"
}
