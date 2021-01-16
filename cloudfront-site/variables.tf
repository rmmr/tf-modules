variable "zone_id" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "aliases" {
  type    = set(string)
  default = []
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

variable "index_document" {
  type    = string
  default = null
}

variable "cache_behavior" {
  type    = any
  default = null
}

variable "custom_error_response" {
  type    = any
  default = {}
}

variable "geo_restriction" {
  type    = any
  default = {}
}
