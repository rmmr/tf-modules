variable "name" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "serverless_next_dir" {
  type = string
}

variable "next_dir" {
  type = string
}

variable "default_lambda_package" {
  type = string
}

variable "api_lambda_package" {
  type = string
}

variable "bucket_name" {
  type    = string
  default = null
}

variable "price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "enabled" {
  type    = bool
  default = true
}

variable "nodejs_version" {
  type    = string
  default = "12.x"
}
variable "timeout" {
  type    = number
  default = null
}

variable "memory_size" {
  type    = string
  default = 512
}

variable "custom_headers" {
  type    = list(string)
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
