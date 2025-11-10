variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "allowed_security_group_ids" {
  type    = list(string)
  default = []
}

variable "engine_version" {
  type    = string
  default = "15.5"
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "port" {
  type    = number
  default = 5432
}

variable "backup_retention_days" {
  type    = number
  default = 3
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "master_username" {
  type    = string
  default = "appuser"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "create_secret" {
  type    = bool
  default = true
}
