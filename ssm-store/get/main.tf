data "aws_ssm_parameter" "this" {
  for_each = var.keys
  name     = "/${var.name}/${each.value}"
}
