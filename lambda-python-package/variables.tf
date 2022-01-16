variable "python_version" {
  type    = string
  default = "3.8"
}

variable "source_dir" {
  type = string
}

variable "output_file" {
  type = string
}

variable "exclude_packages" {
  type    = list(string)
  default = ["botocore", "boto3"]
}

variable "env" {
  type    = map(string)
  default = {}
}
