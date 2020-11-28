resource "aws_ssm_parameter" "strings" {
  for_each = var.string
  name     = "/${var.name}/${each.key}"
  type     = "String"
  value    = each.value
}

resource "aws_ssm_parameter" "lists" {
  for_each = var.list
  name     = "/${var.name}/${each.key}"
  type     = "StringList"
  value    = join(",", each.value)
}
