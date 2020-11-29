locals {
  api_gateway_functions = {
    for key, function in var.functions :
    key => function
    if contains([for event in function.events : event.type], "http")
  }
}

module "api_gateway_acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> v2.0"

  domain_name = var.domain_name
  zone_id     = var.zone_id
}

resource "aws_route53_record" "api_gateway" {
  name    = var.domain_name
  type    = "A"
  zone_id = var.zone_id

  alias {
    name                   = module.api_gateway.this_apigatewayv2_domain_name_configuration[0].target_domain_name
    zone_id                = module.api_gateway.this_apigatewayv2_domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name = "/aws/api-gateway/${var.name}"
}

module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = var.name
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["*"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  domain_name                 = var.domain_name
  domain_name_certificate_arn = module.api_gateway_acm.this_acm_certificate_arn

  default_stage_access_log_destination_arn = aws_cloudwatch_log_group.api_gateway.arn
  default_stage_access_log_format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"

  integrations = merge([
    for key, function in local.api_gateway_functions :
    merge([
      for event in function.events :
      {
        (event.route) : module.lambda[key].this_lambda_function_arn
      }
      if event.type == "http"
    ]...)
    ]...
  )
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
  publish       = try(each.value.publish, null)

  provisioned_concurrent_executions = try(each.value.provisioned_concurrent_executions, null)

  allowed_actions = try(each.value.allowed_actions, null)

  subnet_ids            = try(each.value.subnet_ids, null)
  security_group_ids    = try(each.value.security_group_ids, null)
  attach_network_policy = try(each.value.attach_network_policy, null)

  filename          = try(each.value.filename, null)
  s3_bucket         = try(each.value.s3_bucket, null)
  s3_key            = try(each.value.s3_key, null)
  s3_object_version = try(each.value.s3_object_version, null)
  source_code_hash  = try(each.value.source_code_hash, null)

  allowed_triggers = {
    AllowExecutionFromAPIGateway = can(local.api_gateway_functions[key]) ? {
      service    = "apigateway"
      source_arn = "${module.api_gateway.this_apigatewayv2_api_execution_arn}/*"
    } : null
  }

  tags = try(each.value.tags, null)
}

