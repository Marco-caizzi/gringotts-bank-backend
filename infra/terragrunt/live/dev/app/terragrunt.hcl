terraform {
  source = "${get_repo_root()}/infra/terraform/app"
}

include "env" {
  path = find_in_parent_folders("env.hcl")
}

inputs = {
  # Keep RDS disabled in dev until VPC inputs are provided.
  create_rds = false

  # When enabling, provide vpc/subnets and rds settings here.
  # vpc_id              = "vpc-xxxxxxxx"
  # private_subnet_ids  = ["subnet-aaaa", "subnet-bbbb"]
  # allowed_security_group_ids = ["sg-xxxxxx"]
  # rds = {
  #   name = "gringotts-dev"
  # }
}
variable "name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "allowed_security_group_ids" { type = list(string) default = [] }

variable "engine_version" { type = string default = "15.5" }
variable "instance_class" { type = string default = "db.t3.micro" }
variable "allocated_storage" { type = number default = 20 }
variable "port" { type = number default = 5432 }
variable "backup_retention_days" { type = number default = 3 }
variable "deletion_protection" { type = bool default = false }
variable "skip_final_snapshot" { type = bool default = true }
variable "multi_az" { type = bool default = false }
variable "master_username" { type = string default = "appuser" }

