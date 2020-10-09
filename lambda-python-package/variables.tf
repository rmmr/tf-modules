variable "source_dir" {
  type = string
}

variable "output_file" {
  type = string
}

variable "env" {
  type    = map(string)
  default = {}
}
