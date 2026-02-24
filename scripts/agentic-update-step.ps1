param(
  [Parameter(Mandatory = $true)][string]$RunDir,
  [Parameter(Mandatory = $true)][ValidateSet("architect", "build", "test", "security", "migration", "release")][string]$Agent,
  [Parameter(Mandatory = $true)][ValidateSet("pending", "in_progress", "done", "blocked")][string]$Status,
  [string]$Notes = ""
)

$ErrorActionPreference = "Stop"

$resolvedRunDir = Resolve-Path $RunDir
$runJsonPath = Join-Path $resolvedRunDir "run.json"

if (-not (Test-Path $runJsonPath)) {
  throw "run.json not found: $runJsonPath"
}

$run = Get-Content -Raw -Encoding UTF8 $runJsonPath | ConvertFrom-Json
$run.status.$Agent = $Status

$logItem = [ordered]@{
  time = (Get-Date).ToString("s")
  agent = $Agent
  status = $Status
  notes = $Notes
}

$newLogs = @()
if ($run.logs) {
  $newLogs += $run.logs
}
$newLogs += $logItem
$run.logs = $newLogs

$run | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $runJsonPath

$stepIndex = @{
  architect = "01"
  build = "02"
  test = "03"
  security = "04"
  migration = "05"
  release = "06"
}

$stepFile = Join-Path $resolvedRunDir ("{0}-{1}.md" -f $stepIndex[$Agent], $Agent)
if (Test-Path $stepFile) {
  Add-Content -Encoding UTF8 $stepFile ""
  Add-Content -Encoding UTF8 $stepFile ("- [{0}] status={1} notes={2}" -f (Get-Date).ToString("s"), $Status, $Notes)
}

Write-Host ("Updated {0}: {1}" -f $Agent, $Status)
