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


}

module "lambda" {
  source = "../lambda"

  for_each = var.functions

  function_name = "${var.name}-${each.key}"
  handler       = each.value.handler
  runtime       = each.value.runtime

}

