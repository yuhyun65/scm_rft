param(
  [string]$Tag = "scm231-local",
  [string]$ImagePrefix = "scm-rft",
  [string]$EvidenceDir = "runbooks/evidence/SCM-231",
  [switch]$NoCache
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  throw "docker command not found."
}

$services = @(
  "auth",
  "member",
  "board",
  "quality-doc",
  "order-lot",
  "inventory",
  "file",
  "report",
  "gateway"
)

$evDir = Join-Path $repoRoot $EvidenceDir
New-Item -ItemType Directory -Force -Path $evDir | Out-Null

$summary = [System.Collections.Generic.List[string]]::new()
$summary.Add("# SCM-231 Docker Image Build Summary")
$summary.Add("")
$summary.Add("- Tag: $Tag")
$summary.Add("- ImagePrefix: $ImagePrefix")
$summary.Add("- GeneratedAt: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")")
$summary.Add("")
$summary.Add("| Service | Image | Result | Log |")
$summary.Add("|---|---|---|---|")

foreach ($svc in $services) {
  $dockerfile = "services/$svc/Dockerfile"
  if (-not (Test-Path $dockerfile)) {
    throw "Dockerfile missing: $dockerfile"
  }

  $image = "{0}/{1}:{2}" -f $ImagePrefix, $svc, $Tag
  $log = Join-Path $evDir ("docker-build-{0}.log" -f $svc)
  $err = "$log.err"

  $args = @("build", "-f", $dockerfile, "-t", $image)
  if ($NoCache) {
    $args += "--no-cache"
  }
  $args += "."

  Write-Host ("[INFO] building {0}" -f $image)
  if (Test-Path $log) { Remove-Item -Force $log }
  if (Test-Path $err) { Remove-Item -Force $err }

  $proc = Start-Process -FilePath "docker" -ArgumentList $args -NoNewWindow -Wait -PassThru -RedirectStandardOutput $log -RedirectStandardError $err
  if (Test-Path $err) {
    $errText = Get-Content -Raw -Encoding UTF8 $err
    if (-not [string]::IsNullOrWhiteSpace($errText)) {
      Add-Content -Path $log -Value $errText -Encoding UTF8
    }
    Remove-Item -Force $err
  }

  $logRel = $log.Replace($repoRoot.Path + "\", "")
  if ($proc.ExitCode -ne 0) {
    $summary.Add("| $svc | $image | FAIL | $logRel |")
    $summaryPath = Join-Path $evDir "image-build-summary.md"
    $summary | Set-Content -Encoding UTF8 $summaryPath
    throw "docker build failed for $svc"
  }

  $summary.Add("| $svc | $image | PASS | $logRel |")
}

$summaryPath = Join-Path $evDir "image-build-summary.md"
$summary | Set-Content -Encoding UTF8 $summaryPath

Write-Host ("[OK] all images built: {0}" -f $services.Count)
Write-Host ("[OK] summary: {0}" -f $summaryPath)
