variable "name" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "functions" {
  type    = map
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
