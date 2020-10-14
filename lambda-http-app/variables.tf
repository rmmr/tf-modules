variable "name" {
  type = string
}

variable "runtime" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "handler" {
  type = string
}

variable "security_group_ids" {
  type    = list(string)
  default = null
}

variable "subnet_ids" {
  type    = list(string)
  default = null
}

variable "timeout" {
  type    = number
  default = null
}

variable "package_s3_bucket" {
  type    = string
  default = null
}

variable "package_s3_key" {
  type    = string
  default = null
}

variable "package_s3_object_version" {
  type    = string
  default = null
}

variable "package_filename" {
  type    = string
  default = null
}

variable "source_code_hash" {
  type    = string
  default = null
}

variable "memory_size" {
  type    = string
  default = 512
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "env" {
  type    = map(string)
  default = {}
}

variable "handlers" {
  description = "Map of additional handlers to configure."
  type        = map
  default     = {}
}

variable "provisioned_concurrent_executions" {
  type    = number
  default = null
}

variable "allowed_actions" {
  type    = map(map(any))
  default = {}
}
