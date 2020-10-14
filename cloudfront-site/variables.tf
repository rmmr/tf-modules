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

variable "price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "enabled" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "default_root_object" {
  type    = string
  default = null
}

variable "cache_behavior" {
  type    = any
  default = null
}
