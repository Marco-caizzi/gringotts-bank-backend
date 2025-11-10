output "rds_endpoint" {
  value       = try(module.rds[0].endpoint, null)
  description = "RDS endpoint (if created)"
}

output "rds_port" {
  value       = try(module.rds[0].port, null)
  description = "RDS port (if created)"
}

output "rds_security_group_id" {
  value       = try(module.rds[0].security_group_id, null)
  description = "RDS security group (if created)"
}

output "rds_username" {
  value       = try(module.rds[0].username, null)
  sensitive   = false
  description = "Master username (if created)"
}

output "rds_secret_arn" {
  value       = try(module.rds[0].secret_arn, null)
  description = "Secrets Manager ARN for DB credentials (if created)"
}
