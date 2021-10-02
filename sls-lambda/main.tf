locals {
  api_gateway_functions = {
    for key, function in var.functions :
    key => function
    if contains([for event in function.events : event.type], "http")
  }

  sqs_events = merge({}, [
    for key, function in var.functions :
    merge([
      for event in function.events :
      {
        (event.queue_arn) = key
      }
      if event.type == "sqs"
    ]...)
  ]...)

  s3_events = merge({}, [
    for key, function in var.functions :
    merge([
      for event in function.events :
      {
        ("${key}-${event.type}") = {
          function = key
          type     = event.type
          bucket   = event.bucket
        }
      }
      if split(":", event.type)[0] == "s3"
    ]...)
  ]...)

  schedule_events = merge({}, [
    for key, function in var.functions :
    merge([
      for event in function.events :
      {
        ("${key}-${event.name}") = {
          function   = key
          expression = event.expression
        }
      }
      if event.type == "schedule"
    ]...)
  ]...)
}

module "api_gateway_acm" {
  count = var.domain_name != null ? 1 : 0

  source  = "terraform-aws-modules/acm/aws"
  version = "~> v2.0"

  domain_name = var.domain_name
  zone_id     = var.zone_id
}

resource "aws_route53_record" "api_gateway" {
  count = var.domain_name != null ? 1 : 0

  name    = var.domain_name
  type    = "A"
  zone_id = var.zone_id

  alias {
    name                   = module.api_gateway[0].apigatewayv2_domain_name_configuration[0].target_domain_name
    zone_id                = module.api_gateway[0].apigatewayv2_domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  count = var.domain_name != null ? 1 : 0
  name  = "/aws/api-gateway/${var.name}"
}

module "api_gateway" {
  count = var.domain_name != null ? 1 : 0

  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = var.name
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["*"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  domain_name                 = var.domain_name
  domain_name_certificate_arn = module.api_gateway_acm[0].this_acm_certificate_arn

  default_stage_access_log_destination_arn = aws_cloudwatch_log_group.api_gateway[0].arn
  default_stage_access_log_format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"

  integrations = merge([
    for key, function in local.api_gateway_functions :
    merge([
      for event in function.events :
      {
        (event.route) = {
          lambda_arn = module.lambda[key].this_lambda_function_arn
        }
      }
      if event.type == "http"
    ]...)
    ]...
  )
}

resource "aws_lambda_event_source_mapping" "sqs" {
  for_each = local.sqs_events

  event_source_arn = each.key
  function_name    = module.lambda[each.value].this_lambda_function_arn
}

resource "aws_s3_bucket_notification" "notification" {
  for_each = local.s3_events

  bucket = each.value.bucket

  lambda_function {
    lambda_function_arn = module.lambda[each.value.function].this_lambda_function_arn
    events              = [each.value.event]
  }
}

resource "aws_cloudwatch_event_rule" "rule" {
  for_each = local.schedule_events

  name                = each.key
  schedule_expression = each.value.expression
}

resource "aws_cloudwatch_event_target" "target" {
  for_each = local.schedule_events

  rule = aws_cloudwatch_event_rule.rule[each.key].name
  arn  = module.lambda[each.value.function].this_lambda_function_arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  for_each = local.schedule_events

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda[each.value.function].this_lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rule[each.key].arn
}

module "lambda" {
  source = "../lambda"

  for_each = var.functions

  function_name = "${var.name}-${each.key}"
  handler       = each.value.handler
  runtime       = each.value.runtime
  memory_size   = try(each.value.memory_size, null)
  timeout       = try(each.value.timeout, null)
  env           = try(each.value.env, null)
  publish       = try(each.value.publish, false)

  provisioned_concurrent_executions = try(each.value.provisioned_concurrent_executions, -1)

  allowed_actions = try(each.value.allowed_actions, {})

  subnet_ids            = try(each.value.subnet_ids, null)
  security_group_ids    = try(each.value.security_group_ids, null)
  attach_network_policy = try(each.value.attach_network_policy, false)

  filename          = try(each.value.filename, null)
  s3_bucket         = try(each.value.s3_bucket, null)
  s3_key            = try(each.value.s3_key, null)
  s3_object_version = try(each.value.s3_object_version, null)
  source_code_hash  = try(each.value.source_code_hash, null)

  allowed_triggers = contains([for event in each.value.events : event.type], "http") ? {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway[0].apigatewayv2_api_execution_arn}/*"
    }
  } : {}

  tags = try(each.value.tags, {})
}

