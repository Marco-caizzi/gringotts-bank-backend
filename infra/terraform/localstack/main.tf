terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = var.region
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    apigateway  = var.localstack_endpoint
    cloudwatch  = var.localstack_endpoint
    dynamodb    = var.localstack_endpoint
    iam         = var.localstack_endpoint
    lambda      = var.localstack_endpoint
    logs        = var.localstack_endpoint
    s3          = var.localstack_endpoint
    sts         = var.localstack_endpoint
  }
}

locals {
  computed_package_path = coalesce(var.package_path, "${path.module}/../../../dist/health.zip")
}

module "lambda_api_gateway" {
  source             = "../modules/lambda_api_gateway_rest"
  region             = var.region
  lambda_name        = var.lambda_name
  lambda_description = "Health endpoint"
  handler            = "bootstrap"
  runtime            = "provided.al2023"
  memory_size        = 128
  timeout            = 5
  package_path       = local.computed_package_path
  environment = {
    ENV       = "local"
    LOG_LEVEL = "info"
  }
  stage_name = "local"
}

output "api_endpoint" {
  value = "${var.localstack_endpoint}/restapis/${module.lambda_api_gateway.rest_api_id}/${module.lambda_api_gateway.stage_name}/_user_request_"
}
