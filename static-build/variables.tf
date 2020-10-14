variable "cmd" {
  type = string
}

variable "output_dir" {
  type = string
}

variable "cwd" {
  type    = string
  default = null
}

variable "triggers" {
  type    = map(string)
  default = null
}

variable env {
  type    = map(any)
  default = null
}
