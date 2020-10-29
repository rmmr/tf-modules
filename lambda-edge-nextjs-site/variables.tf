variable "name" {
  type = string
}

variable "source_dir" {
  type = string
}

variable "content_dir" {
  type    = string
  default = null
}

variable "build_dir" {
  type = string
}

variable "nodejs_version" {
  type    = string
  default = "12.x"
}

variable "zone_id" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "bucket_name" {
  type    = string
  default = null
}

variable "timeout" {
  type    = number
  default = null
}

variable "memory_size" {
  type    = string
  default = 512
}

variable "extra_dependencies" {
  type    = map(any)
  default = {}
}

variable "npm_config" {
  type    = string
  default = ""
}

variable "env" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
