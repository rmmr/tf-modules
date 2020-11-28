variable "name" {
  description = "Name of the paramter store"
  type        = string
}

variable "string" {
  type    = map(string)
  default = {}
}

variable "list" {
  type    = map(list(string))
  default = {}
}
