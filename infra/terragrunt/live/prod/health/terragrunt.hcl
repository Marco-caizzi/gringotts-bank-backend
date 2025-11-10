terraform {
  source = "${get_repo_root()}/infra/terraform/modules/lambda_api_gateway"
}

include "env" {
  path = find_in_parent_folders("env.hcl")
}

dependency "app" {
  config_path = "../app"
  mock_outputs = {
    rds_secret_arn = null
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
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
    ENV           = "prod"
    LOG_LEVEL     = "info"
    DB_SECRET_ARN = try(dependency.app.outputs.rds_secret_arn, "")
  }
}

