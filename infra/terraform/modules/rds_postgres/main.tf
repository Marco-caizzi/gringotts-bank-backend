resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "this" {
  name        = "${var.name}-rds-sg"
  description = "Security group for RDS Postgres"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "random_password" "db" {
  length  = 20
  special = true
}

resource "aws_db_instance" "this" {
  identifier              = var.name
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  username                = var.master_username
  password                = random_password.db.result
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.this.id]
  port                    = var.port
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_days
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  publicly_accessible     = false
  db_name                 = var.db_name
}

# Optional Secrets Manager secret containing connection details
resource "aws_secretsmanager_secret" "db" {
  count = var.create_secret ? 1 : 0
  name  = "${var.name}-db-credentials"
}

resource "aws_secretsmanager_secret_version" "db" {
  count      = var.create_secret ? 1 : 0
  secret_id  = aws_secretsmanager_secret.db[0].id
  secret_string = jsonencode({
    host     = aws_db_instance.this.address
    port     = var.port
    db       = var.db_name
    username = var.master_username
    password = random_password.db.result
  })
}
