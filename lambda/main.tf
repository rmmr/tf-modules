locals {
  log_group_arn_regional = aws_cloudwatch_log_group.lambda.arn
  log_group_arn          = var.edge ? format("arn:%s:%s:%s:%s:%s", data.aws_arn.log_group_arn.partition, data.aws_arn.log_group_arn.service, "*", data.aws_arn.log_group_arn.account, data.aws_arn.log_group_arn.resource) : local.log_group_arn_regional
}

data "aws_arn" "log_group_arn" {
  arn = local.log_group_arn_regional
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 1
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = concat(["lambda.amazonaws.com"], var.edge ? ["edgelambda.amazonaws.com"] : [])
    }
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = flatten([for _, v in ["%v:*", "%v:*:*"] : format(v, local.log_group_arn)])
  }

  dynamic "statement" {
    for_each = var.allowed_actions
    content {
      effect    = "Allow"
      actions   = lookup(statement.value, "actions", null)
      resources = lookup(statement.value, "resources", null)
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

resource "aws_iam_policy" "lambda" {
  name   = var.function_name
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_policy_attachment" "lambda" {
  name       = var.function_name
  roles      = [aws_iam_role.lambda.name]
  policy_arn = aws_iam_policy.lambda.arn
}

data "aws_iam_policy" "vpc" {
  count = var.attach_network_policy ? 1 : 0

  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
}

resource "aws_iam_policy" "vpc" {
  count = var.attach_network_policy ? 1 : 0

  name   = "${var.function_name}-vpc"
  policy = data.aws_iam_policy.vpc[0].policy
}

resource "aws_iam_policy_attachment" "vpc" {
  count = var.attach_network_policy ? 1 : 0

  name       = "${var.function_name}-vpc"
  roles      = [aws_iam_role.lambda.name]
  policy_arn = aws_iam_policy.vpc[0].arn
}

resource "aws_lambda_function" "this" {
  function_name                  = var.function_name
  description                    = var.description
  handler                        = var.handler
  memory_size                    = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrent_executions
  runtime                        = var.runtime
  timeout                        = var.timeout
  publish                        = var.publish || var.edge
  role                           = aws_iam_role.lambda.arn

  filename         = var.filename
  source_code_hash = var.source_code_hash

  s3_bucket         = var.s3_bucket
  s3_key            = var.s3_key
  s3_object_version = var.s3_object_version

  layers = var.layers

  image_uri    = var.image_uri
  package_type = var.package_type

  dynamic "environment" {
    for_each = var.env != null ? [true] : []
    content {
      variables = var.env
    }
  }

  dynamic "vpc_config" {
    for_each = var.subnet_ids != null && var.security_group_ids != null ? [true] : []
    content {
      security_group_ids = var.security_group_ids
      subnet_ids         = var.subnet_ids
    }
  }

  tags = var.tags
}

resource "aws_lambda_permission" "triggers" {
  for_each = var.allowed_triggers

  function_name = aws_lambda_function.this.function_name
  qualifier     = var.publish ? aws_lambda_function.this.version : null

  statement_id       = lookup(each.value, "statement_id", each.key)
  action             = lookup(each.value, "action", "lambda:InvokeFunction")
  principal          = lookup(each.value, "principal", format("%s.amazonaws.com", lookup(each.value, "service", "")))
  source_arn         = lookup(each.value, "source_arn", null)
  source_account     = lookup(each.value, "source_account", null)
  event_source_token = lookup(each.value, "event_source_token", null)
}

resource "aws_lambda_permission" "unqualified_alias_triggers" {
  for_each = var.publish ? var.allowed_triggers : {}

  function_name = aws_lambda_function.this.function_name

  statement_id       = lookup(each.value, "statement_id", each.key)
  action             = lookup(each.value, "action", "lambda:InvokeFunction")
  principal          = lookup(each.value, "principal", format("%s.amazonaws.com", lookup(each.value, "service", "")))
  source_arn         = lookup(each.value, "source_arn", null)
  source_account     = lookup(each.value, "source_account", null)
  event_source_token = lookup(each.value, "event_source_token", null)
}

resource "aws_lambda_provisioned_concurrency_config" "current_version" {
  count = var.provisioned_concurrent_executions > -1 ? 1 : 0

  function_name = aws_lambda_function.this.function_name
  qualifier     = aws_lambda_function.this.version

  provisioned_concurrent_executions = var.provisioned_concurrent_executions
}
