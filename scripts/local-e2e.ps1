param(
  [ValidateSet("up","down","deploy","invoke")] [string]$Action = "up",
  [switch]$SkipHealth
)

$ErrorActionPreference = "Stop"

function Write-Log { param($Msg) Write-Host "[local-e2e] $Msg" }
function Write-Err { param($Msg) Write-Host "[local-e2e][ERROR] $Msg" -ForegroundColor Red }

# Paths
$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$TfDir   = Join-Path $RootDir "infra/terraform/localstack"
$DistDir = Join-Path $RootDir "dist"
$ZipPath = Join-Path $DistDir "health.zip"
$BootstrapPath = Join-Path $RootDir "bootstrap"

function Get-DockerComposeCommand {
  if (Get-Command docker -ErrorAction SilentlyContinue) {
    try { docker compose version | Out-Null; return @("docker","compose") } catch { }
    if (Get-Command docker-compose -ErrorAction SilentlyContinue) { return @("docker-compose") }
  }
  throw "Docker compose command not found (docker compose / docker-compose)"
}

function Wait-LocalStack {
  param([string]$Url = "http://localhost:4566", [int]$MaxRetries = 60)
  Write-Log "Waiting for LocalStack at $Url ..."
  for ($i=0; $i -lt $MaxRetries; $i++) {
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "$Url/_localstack/health" -TimeoutSec 3
      if ($resp.StatusCode -eq 200) { Write-Log "LocalStack is up."; return }
    } catch { }
    Start-Sleep -Seconds 2
  }
  throw "LocalStack did not become ready after $MaxRetries attempts"
}

function Build-Lambda {
  Write-Log "Building AWS Lambda bootstrap (GOOS=linux GOARCH=amd64)"
  pushd $RootDir | Out-Null
  $env:GOOS = "linux"; $env:GOARCH = "amd64"; $env:CGO_ENABLED = "0"
  go build -tags "lambda.norpc" -ldflags "-s -w" -o $BootstrapPath ./lambda/GetHealthcheckAPI/cmd
  if (!(Test-Path $DistDir)) { New-Item -ItemType Directory -Path $DistDir | Out-Null }
  if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
  Compress-Archive -Path $BootstrapPath -DestinationPath $ZipPath -Force
  # Clean bootstrap binary (keep only zip)
  if (Test-Path $BootstrapPath) { Remove-Item $BootstrapPath -Force }
  Write-Log "Package created at $ZipPath"
  popd | Out-Null
}

function Deploy-Terraform {
  Write-Log "Applying Terraform to LocalStack..."
  pushd $TfDir | Out-Null
  terraform init -input=false
  terraform apply -auto-approve
  $api = terraform output -raw api_endpoint
  if (-not $api) { throw "api_endpoint output not found" }
  if (!(Test-Path $DistDir)) { New-Item -ItemType Directory -Path $DistDir | Out-Null }
  $api | Out-File -FilePath (Join-Path $DistDir "api_endpoint.txt") -Encoding ascii
  Write-Log "API endpoint: $api"
  popd | Out-Null
}

function Invoke-Health {
  $file = Join-Path $DistDir "api_endpoint.txt"
  if (!(Test-Path $file)) { throw "api_endpoint.txt not found; run with -Action deploy or up first" }
  $endpoint = (Get-Content $file | Select-Object -First 1).TrimEnd('/')
  $health = "$endpoint/health"
  Write-Log "Invoking GET $health ..."
  try {
    $resp = Invoke-WebRequest -UseBasicParsing -Uri $health -TimeoutSec 5
    Write-Host "Status: $($resp.StatusCode)"
    Write-Host $resp.Content
  } catch {
    Write-Err $_
    throw
  }
}

switch ($Action) {
  'up' {
    $dc = Get-DockerComposeCommand
    Write-Log "Starting LocalStack via Docker Compose..."
    & $dc up -d localstack
    Wait-LocalStack
    Build-Lambda
    Deploy-Terraform
    if (-not $SkipHealth) { Invoke-Health }
  }
  'down' {
    $dc = Get-DockerComposeCommand
    Write-Log "Stopping LocalStack containers..."
    & $dc down
  }
  'deploy' {
    Build-Lambda
    Deploy-Terraform
    if (-not $SkipHealth) { Invoke-Health }
  }
  'invoke' { Invoke-Health }
  default { throw "Unknown action $Action" }
}

Write-Log "Done ($Action)."
