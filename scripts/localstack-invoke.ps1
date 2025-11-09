$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$tfdir = Join-Path $root "infra/terraform/localstack"

Write-Host "Reading Terraform output (api_endpoint) ..."
pushd $tfdir
$endpoint = terraform output -raw api_endpoint
popd

if (-not $endpoint) {
  throw "No se pudo obtener api_endpoint de Terraform. Asegurate de haber corrido tf-local-apply.ps1"
}

# Normalizar endpoint y agregar /health
if ($endpoint.EndsWith("/")) {
  $endpoint = $endpoint.TrimEnd('/')
}
$health = "$endpoint/health"

Write-Host "Invocando $health ..."
try {
  $resp = Invoke-WebRequest -UseBasicParsing -Uri $health -TimeoutSec 5
  Write-Host "Status: $($resp.StatusCode)"
  Write-Output $resp.Content
} catch {
  Write-Error $_
  exit 1
}

