variable "zone_id" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
