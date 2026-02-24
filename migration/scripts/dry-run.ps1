param(
  [string]$RunId = "",
  [string]$ConfigPath = "migration/verify/config.sample.json",
  [string]$OutputDir = "migration/reports",
  [switch]$Resume,
  [switch]$FailOnMismatch
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

if ([string]::IsNullOrWhiteSpace($RunId)) {
  $RunId = "dryrun-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
}

$resolvedOutputDir = if ([System.IO.Path]::IsPathRooted($OutputDir)) { $OutputDir } else { Join-Path $repoRoot $OutputDir }
New-Item -ItemType Directory -Force -Path $resolvedOutputDir | Out-Null
$statePath = Join-Path $resolvedOutputDir ("{0}.state.json" -f $RunId)

if ((-not $Resume) -and (Test-Path $statePath)) {
  Remove-Item -Force $statePath
}

if (Test-Path $statePath) {
  $state = Get-Content -Raw -Encoding UTF8 $statePath | ConvertFrom-Json
}
else {
  $state = [ordered]@{
    runId = $RunId
    startedAt = (Get-Date).ToString("s")
    step = "prepare"
    history = @()
  }
}

function Save-State {
  param([object]$StateObj)
  $StateObj | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $statePath
}

function Mark-Step {
  param(
    [object]$StateObj,
    [string]$StepName,
    [string]$Message
  )

  $StateObj.step = $StepName
  $entry = [ordered]@{
    time = (Get-Date).ToString("s")
    step = $StepName
    message = $Message
  }
  $hist = @()
  if ($StateObj.history) { $hist += $StateObj.history }
  $hist += $entry
  $StateObj.history = $hist
  Save-State -StateObj $StateObj
}

Write-Host ("[INFO] Migration dry-run started. runId={0}" -f $RunId)

if ($state.step -eq "prepare") {
  Mark-Step -StateObj $state -StepName "extract" -Message "Preparation complete."
}

if ($state.step -eq "extract") {
  Mark-Step -StateObj $state -StepName "load" -Message "Extraction placeholder complete."
}

if ($state.step -eq "load") {
  Mark-Step -StateObj $state -StepName "validate" -Message "Load placeholder complete."
}

if ($state.step -eq "validate") {
  $validateScript = Join-Path $repoRoot "migration/verify/validate-migration.ps1"
  if (-not (Test-Path $validateScript)) {
    throw "Validation script not found: $validateScript"
  }

  if ($FailOnMismatch) {
    & powershell -ExecutionPolicy Bypass -File $validateScript -ConfigPath $ConfigPath -OutputDir $OutputDir -FailOnMismatch
  }
  else {
    & powershell -ExecutionPolicy Bypass -File $validateScript -ConfigPath $ConfigPath -OutputDir $OutputDir
  }
  if ($LASTEXITCODE -ne 0) {
    throw "Validation phase failed."
  }

  Mark-Step -StateObj $state -StepName "completed" -Message "Validation complete."
}

if ($state.step -eq "completed") {
  Write-Host ("[OK] Migration dry-run completed. state={0}" -f $statePath)
}
