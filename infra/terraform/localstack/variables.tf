variable "region" {
  type        = string
  default     = "us-east-1"
}

variable "localstack_endpoint" {
  type        = string
  description = "LocalStack edge endpoint"
  default     = "http://localhost:4566"
}

variable "lambda_name" {
  type        = string
  default     = "gringotts-health"
}

variable "package_path" {
  type        = string
  description = "Path to deployment package zip (optional). Defaults to dist/health.zip relative to repo root."
  default     = null
}
