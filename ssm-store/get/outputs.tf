output "values" {
  value = { for key in var.keys :
    key => data.aws_ssm_parameter.this[key].type == "StringList" ? split(",", data.aws_ssm_parameter.this[key].value) : data.aws_ssm_parameter.this[key].value
  }
}
