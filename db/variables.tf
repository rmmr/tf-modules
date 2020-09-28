variable "name" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "subnet_ids" {
  type = list(string)
}

variable "engine" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "engine_family" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "database_name" {
  type = string
}

variable "database_user" {
  type = string
}

variable "database_password" {
  type = string
}

variable "backup_retention_period" {
  type    = number
  default = 14
}

variable "preferred_backup_window" {
  type    = string
  default = null
}

variable "skip_final_snapshot" {
  type    = bool
  default = null
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "instance_class" {
  type = string
}

variable "debug" {
  type    = bool
  default = false
}

variable "require_tls" {
  type    = bool
  default = null
}

variable "idle_client_timeout" {
  type    = number
  default = 1800
}

variable "publicly_accessible" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
