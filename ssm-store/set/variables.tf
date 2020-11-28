variable "name" {
  description = "Name of the paramter store"
  type        = string
}

variable "values" {
  type = map(any)
}


