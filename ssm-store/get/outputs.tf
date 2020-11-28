output "string" {
  value = { for key in var.keys :
    key => data.aws_ssm_parameter.this[key].type == "String" ? data.aws_ssm_parameter.this[key].value : null
  }
}

output "list" {
  value = { for key in var.keys :
    key => data.aws_ssm_parameter.this[key].type == "StringList" ? split(",", data.aws_ssm_parameter.this[key].value) : null
  }
}
