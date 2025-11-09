terraform {
  source = "${get_repo_root()}/infra/terraform/modules/lambda_api_gateway"
}

include "env" {
  path = find_in_parent_folders("env.hcl")
}

inputs = {
  lambda_name        = "gringotts-health"
  lambda_description = "Health endpoint"
  handler            = "bootstrap"
  runtime            = "provided.al2023"
  memory_size        = 128
  timeout            = 5
  package_path       = "${get_repo_root()}/dist/health.zip"
  environment = {
    SERVICE_NAME = "gringotts-bank-backend"
    VERSION      = "0.0.1"
  }
}
