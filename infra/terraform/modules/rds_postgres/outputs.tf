output "endpoint" {
  value = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}

output "security_group_id" {
  value = aws_security_group.this.id
}

output "username" {
  value = var.master_username
}

output "secret_arn" {
  value       = try(aws_secretsmanager_secret.db[0].arn, null)
  description = "Secrets Manager ARN with DB connection details"
}
