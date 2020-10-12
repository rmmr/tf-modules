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

variable "tags" {
  type    = map(string)
  default = {}
}

variable "cache_behavior" {
  type    = map(map(any))
  default = {}
}
