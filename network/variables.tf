variable "aws_region" {
  type = string
}

variable "availability_zones" {
  type    = list(string)
  default = null
}

variable "security_group_ids" {
  type = list(string)
  default = null
}

variable "cidr_block" {
  type    = string
  default = "20.0.0.0/16"
}

variable "enable_s3_endpoint" {
  type    = bool
  default = false
}

variable "enable_dynamodb_endpoint" {
  type    = bool
  default = false
}

variable "enable_sqs_endpoint" {
  type    = bool
  default = false
}

variable "enable_internet_gateway" {
  type    = bool
  default = false
}

variable "enable_dns_hostnames" {
  type    = bool
  default = false
}

variable "create_public_subnet" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
