variable "source_dir" {
  type = string
}

variable "triggers" {
  type    = map()
  default = {}
}

variable "env" {
  type    = map(string)
  default = {}
}

variable "minify_handlers" {
  type    = bool
  default = true
}

variable "use_serverless_trace_targets" {
  type    = bool
  default = false
}
