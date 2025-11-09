$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$tfdir = Join-Path $root "infra/terraform/localstack"

Write-Host "Destroying Terraform resources on LocalStack..."
pushd $tfdir
terraform destroy -auto-approve
popd

