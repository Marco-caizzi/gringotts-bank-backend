variable "create_rds" { type = bool default = false }

# Defaults vacíos permiten inicializar sin definir VPC/Subnets cuando create_rds=false
variable "vpc_id" { type = string default = "" }
variable "private_subnet_ids" { type = list(string) default = [] }
variable "allowed_security_group_ids" { type = list(string) default = [] }

variable "rds" {
  type = object({
    name                = string
    engine_version      = optional(string, "15.5")
    instance_class      = optional(string, "db.t3.micro")
    allocated_storage   = optional(number, 20)
    port                = optional(number, 5432)
    backup_retention_days = optional(number, 3)
    deletion_protection = optional(bool, false)
    skip_final_snapshot = optional(bool, true)
    multi_az            = optional(bool, false)
    master_username     = optional(string, "appuser")
  })
  default = {
    name = "placeholder" # Se sobreescribe cuando create_rds=true
  }
}
