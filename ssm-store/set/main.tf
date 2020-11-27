resource "aws_ssm_parameter" "this" {
  for_each = var.values
  name     = "/${var.name}/${each.key}"
  type     = can(tostring(each.value)) ? "String" : "StringList"
  value    = can(tostring(each.value)) ? value : join(",", each.value)
}
