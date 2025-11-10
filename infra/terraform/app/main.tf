terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

# This root aggregates optional infrastructure pieces.
# For now, only RDS is exposed and can be toggled via create_rds.

locals {
  create_rds = var.create_rds
}

module "rds" {
  count                      = local.create_rds ? 1 : 0
  source                     = "../modules/rds_postgres"
  name                       = var.rds.name
  vpc_id                     = var.vpc_id
  private_subnet_ids         = var.private_subnet_ids
  allowed_security_group_ids = var.allowed_security_group_ids
  engine_version             = var.rds.engine_version
  instance_class             = var.rds.instance_class
  allocated_storage          = var.rds.allocated_storage
  port                       = var.rds.port
  backup_retention_days      = var.rds.backup_retention_days
  deletion_protection        = var.rds.deletion_protection
  skip_final_snapshot        = var.rds.skip_final_snapshot
  multi_az                   = var.rds.multi_az
  master_username            = var.rds.master_username
}

