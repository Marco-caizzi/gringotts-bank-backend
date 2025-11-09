$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$tfdir = Join-Path $root "infra/terraform/localstack"

Write-Host "Building deployment package (dist/health.zip)"
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "scripts/build.ps1")

Write-Host "Applying Terraform to LocalStack..."
pushd $tfdir
terraform init -input=false
terraform apply -auto-approve
popd

