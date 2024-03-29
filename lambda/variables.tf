variable "function_name" {
  type = string
}

variable "description" {
  type    = string
  default = null
}

variable "runtime" {
  type = string
}

variable "handler" {
  type = string
}

variable "memory_size" {
  type    = string
  default = 128
}

variable "env" {
  type    = map(string)
  default = null
}

variable "timeout" {
  type    = number
  default = null
}

variable "package_type" {
  type    = string
  default = null
}

variable "image_uri" {
  type    = string
  default = null
}

variable "s3_bucket" {
  type    = string
  default = null
}

variable "s3_key" {
  type    = string
  default = null
}

variable "s3_object_version" {
  type    = string
  default = null
}

variable "filename" {
  type    = string
  default = null
}

variable "source_code_hash" {
  type    = string
  default = null
}

variable "layers" {
  type    = list(string)
  default = null
}

variable "image_config" {
  type    = map(any)
  default = null
}


variable "reserved_concurrent_executions" {
  type    = number
  default = null
}

variable "publish" {
  type    = bool
  default = false
}

variable "edge" {
  type    = bool
  default = false
}

variable "security_group_ids" {
  type    = list(string)
  default = null
}

variable "subnet_ids" {
  type    = list(string)
  default = null
}

variable "attach_network_policy" {
  type    = bool
  default = false
}

variable "allowed_triggers" {
  type    = map(any)
  default = {}
}

variable "provisioned_concurrent_executions" {
  type    = number
  default = -1
}

variable "allowed_actions" {
  type    = map(map(any))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
