terraform {
  source = "${get_repo_root()}/infra/terraform/app"
}

include "env" {
  path = find_in_parent_folders("env.hcl")
}

# Prod: normalmente create_rds=true. Completar VPC/Subnets/SG antes del apply.
inputs = {
  create_rds = true

  # vpc_id                     = "vpc-xxxxxxxx"
  # private_subnet_ids         = ["subnet-aaaa", "subnet-bbbb"]
  # allowed_security_group_ids = ["sg-xxxxxx"]
  rds = {
    name                 = "gringotts-prod"
    engine_version       = "15.5"
    instance_class       = "db.t3.medium"
    allocated_storage    = 50
    backup_retention_days = 7
    deletion_protection  = true
    skip_final_snapshot  = false
    multi_az             = true
    master_username      = "appuser"
  }
}
locals {
  aws_region = "us-east-1"
}

inputs = {
  region = local.aws_region
}

