variable "source_dir" {
  type = string
}

variable "custom_cmd" {
  type    = string
  default = ""
}

variable "output_file" {
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
