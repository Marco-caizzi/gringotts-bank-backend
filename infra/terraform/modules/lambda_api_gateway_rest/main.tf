locals {
  lambda_name        = var.lambda_name
  lambda_description = var.lambda_description
  handler            = var.handler
  runtime            = var.runtime
  memory_size        = var.memory_size
  timeout            = var.timeout
}

resource "aws_iam_role" "lambda" {
  name               = "${local.lambda_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "this" {
  function_name = local.lambda_name
  description   = local.lambda_description
  role          = aws_iam_role.lambda.arn
  handler       = local.handler
  runtime       = local.runtime
  filename      = var.package_path
  source_code_hash = filebase64sha256(var.package_path)
  timeout       = local.timeout
  memory_size   = local.memory_size
  environment {
    variables = var.environment
  }
}

# API Gateway REST (v1)
resource "aws_api_gateway_rest_api" "http" {
  name = "${local.lambda_name}-api"
}

# /health resource
resource "aws_api_gateway_resource" "health" {
  rest_api_id = aws_api_gateway_rest_api.http.id
  parent_id   = aws_api_gateway_rest_api.http.root_resource_id
  path_part   = "health"
}

resource "aws_api_gateway_method" "get_health" {
  rest_api_id   = aws_api_gateway_rest_api.http.id
  resource_id   = aws_api_gateway_resource.health.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_health" {
  rest_api_id             = aws_api_gateway_rest_api.http.id
  resource_id             = aws_api_gateway_resource.health.id
  http_method             = aws_api_gateway_method.get_health.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.this.arn}/invocations"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.http.execution_arn}/*/*"
}

# Deployment and stage
resource "aws_api_gateway_deployment" "current" {
  rest_api_id = aws_api_gateway_rest_api.http.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.get_health.id,
      aws_api_gateway_integration.get_health.id,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  rest_api_id  = aws_api_gateway_rest_api.http.id
  deployment_id = aws_api_gateway_deployment.current.id
  stage_name   = var.stage_name
}

output "rest_api_id" {
  value = aws_api_gateway_rest_api.http.id
}

output "stage_name" {
  value = aws_api_gateway_stage.stage.stage_name
}
variable "region" {
  type        = string
  description = "AWS region"
}

variable "lambda_name" {
  type        = string
  description = "Lambda function name"
}

variable "lambda_description" {
  type        = string
  default     = ""
}

variable "handler" {
  type        = string
  description = "Lambda handler"
}

variable "runtime" {
  type        = string
  description = "Lambda runtime"
}

variable "memory_size" {
  type        = number
  default     = 128
}

variable "timeout" {
  type        = number
  default     = 10
}

variable "package_path" {
  type        = string
  description = "Path to deployment package zip"
}

variable "environment" {
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  type        = number
  default     = 14
}

variable "stage_name" {
  type        = string
  default     = "dev"
}
