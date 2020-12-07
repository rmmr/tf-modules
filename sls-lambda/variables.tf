variable "name" {
  type = string
}

variable "zone_id" {
  type    = string
  default = null
}

variable "domain_name" {
  type    = string
  default = null
}

variable "functions" {
  type    = map
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
