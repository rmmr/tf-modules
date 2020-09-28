resource "random_string" "secret_key" {
  length  = 16
  special = false
}

locals {
  runtime = "python${var.python_version}"
  env = merge({
    DEBUG      = 1
    SECRET_KEY = random_string.secret_key.result
  }, var.env)
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> v2.0"

  domain_name = var.domain_name
  zone_id     = var.zone_id
  tags        = var.tags
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
  domain_name_certificate_arn = module.acm.this_acm_certificate_arn

  default_stage_access_log_destination_arn = aws_cloudwatch_log_group.api_gateway.arn
  default_stage_access_log_format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"

  integrations = {
    "$default" = {
      lambda_arn = module.asgi_lambda.this_lambda_function_arn
    }
  }

  tags = var.tags
}

resource "aws_route53_record" "_" {
  name    = var.domain_name
  type    = "A"
  zone_id = var.zone_id

  alias {
    name                   = module.api_gateway.this_apigatewayv2_domain_name_configuration[0].target_domain_name
    zone_id                = module.api_gateway.this_apigatewayv2_domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

module "asgi_lambda" {
  source = "../lambda"

  function_name = "${var.name}-asgi"
  handler       = var.asgi_handler
  runtime       = local.runtime
  memory_size   = var.memory_size
  timeout       = var.timeout
  env           = local.env

  subnet_ids            = var.subnet_ids
  security_group_ids    = var.security_group_ids
  attach_network_policy = var.subnet_ids != null

  filename          = var.package_filename
  s3_bucket         = var.package_s3_bucket
  s3_key            = var.package_s3_key
  s3_object_version = var.package_s3_object_version
  source_code_hash  = var.source_code_hash

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.this_apigatewayv2_api_execution_arn}/*"
    }
  }

  tags = var.tags
}

module "handlers" {
  source = "../lambda"

  for_each = var.handlers

  function_name = "${var.name}-${each.key}"
  handler       = each.value.handler
  runtime       = lookup(each.value, "runtime", local.runtime)
  memory_size   = lookup(each.value, "memory_size", var.memory_size)
  timeout       = lookup(each.value, "timeout", var.timeout)
  env           = merge(lookup(each.value, "env", {}), local.env)

  subnet_ids            = lookup(each.value, "subnet_ids", var.subnet_ids)
  security_group_ids    = lookup(each.value, "security_group_ids", var.security_group_ids)
  attach_network_policy = lookup(each.value, "subnet_ids", var.subnet_ids) != null

  filename          = lookup(each.value, "package_filename", var.package_filename)
  s3_bucket         = lookup(each.value, "package_s3_bucket", var.package_s3_bucket)
  s3_key            = lookup(each.value, "package_s3_key", var.package_s3_key)
  s3_object_version = lookup(each.value, "package_s3_object_version", var.package_s3_object_version)
  source_code_hash  = lookup(each.value, "source_code_hash", var.source_code_hash)

  tags = var.tags
}
