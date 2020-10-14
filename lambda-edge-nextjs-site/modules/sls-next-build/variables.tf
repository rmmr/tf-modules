variable "source_dir" {
  type = string
}

variable "output_dir" {
  type = string
}

variable "extra_dependencies" {
  type    = map(any)
  default = {}
}

variable "npm_config" {
  type    = string
  default = ""
}

variable "env" {
  type    = map(string)
  default = {}
}
