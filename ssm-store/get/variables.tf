variable "name" {
  description = "Name of the paramter store"
  type        = string
}

variable "keys" {
  type = set(string)
}
