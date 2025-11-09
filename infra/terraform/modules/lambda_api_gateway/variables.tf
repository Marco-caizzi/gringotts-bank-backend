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

