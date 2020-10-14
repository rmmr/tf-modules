locals {
  s3_origin_id = "${var.domain_name}-origin"
}

data "aws_region" "current" {

}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> v2.0"

  domain_name = var.domain_name
  zone_id     = var.zone_id

  tags = var.tags
}

resource "aws_s3_bucket" "_" {
  bucket = var.bucket_name != null ? var.bucket_name : replace(var.domain_name, ".", "-")
  acl    = "public-read"

  tags = var.tags
}

resource "aws_cloudfront_distribution" "_" {
  origin {
    // workaround for https://github.com/terraform-providers/terraform-provider-aws/issues/15102
    domain_name = "${aws_s3_bucket._.bucket}.s3.${data.aws_region.current.name}.amazonaws.com"
    origin_id   = local.s3_origin_id
  }

  enabled     = var.enabled
  aliases     = [var.domain_name]
  price_class = var.price_class

  default_root_object = var.default_root_object

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = module.acm.this_acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  dynamic "default_cache_behavior" {
    for_each = [for k, v in var.cache_behavior : v if k == "default"]
    iterator = cb

    content {
      target_origin_id       = lookup(cb.value, "target_origin_id", local.s3_origin_id)
      viewer_protocol_policy = lookup(cb.value, "viewer_protocol_policy", "allow-all")

      allowed_methods           = lookup(cb.value, "allowed_methods", ["GET", "HEAD", "OPTIONS"])
      cached_methods            = lookup(cb.value, "cached_methods", ["GET", "HEAD"])
      compress                  = lookup(cb.value, "compress", null)
      field_level_encryption_id = lookup(cb.value, "field_level_encryption_id", null)
      smooth_streaming          = lookup(cb.value, "smooth_streaming", null)
      trusted_signers           = lookup(cb.value, "trusted_signers", null)

      min_ttl     = lookup(cb.value, "min_ttl", null)
      default_ttl = lookup(cb.value, "default_ttl", null)
      max_ttl     = lookup(cb.value, "max_ttl", null)

      forwarded_values {
        query_string            = lookup(cb.value, "query_string", false)
        query_string_cache_keys = lookup(cb.value, "query_string_cache_keys", [])
        headers                 = lookup(cb.value, "headers", null)

        cookies {
          forward           = lookup(cb.value, "cookies_forward", "none")
          whitelisted_names = lookup(cb.value, "cookies_whitelisted_names", null)
        }
      }

      dynamic "lambda_function_association" {
        for_each = lookup(cb.value, "lambda_function_association", [])
        iterator = lfa

        content {
          event_type   = lfa.key
          lambda_arn   = lfa.value.lambda_arn
          include_body = lookup(lfa.value, "include_body", null)
        }
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = [for k, v in var.cache_behavior : v if k != "default"]
    iterator = cb

    content {
      path_pattern           = cb.value["path_pattern"]
      target_origin_id       = lookup(cb.value, "target_origin_id", local.s3_origin_id)
      viewer_protocol_policy = lookup(cb.value, "viewer_protocol_policy", "allow-all")

      allowed_methods           = lookup(cb.value, "allowed_methods", ["GET", "HEAD", "OPTIONS"])
      cached_methods            = lookup(cb.value, "cached_methods", ["GET", "HEAD"])
      compress                  = lookup(cb.value, "compress", null)
      field_level_encryption_id = lookup(cb.value, "field_level_encryption_id", null)
      smooth_streaming          = lookup(cb.value, "smooth_streaming", null)
      trusted_signers           = lookup(cb.value, "trusted_signers", null)

      min_ttl     = lookup(cb.value, "min_ttl", null)
      default_ttl = lookup(cb.value, "default_ttl", null)
      max_ttl     = lookup(cb.value, "max_ttl", null)

      forwarded_values {
        query_string            = lookup(cb.value, "query_string", false)
        query_string_cache_keys = lookup(cb.value, "query_string_cache_keys", [])
        headers                 = lookup(cb.value, "headers", null)

        cookies {
          forward           = lookup(cb.value, "cookies_forward", "none")
          whitelisted_names = lookup(cb.value, "cookies_whitelisted_names", null)
        }
      }

      dynamic "lambda_function_association" {
        for_each = lookup(cb.value, "lambda_function_association", [])
        iterator = lfa

        content {
          event_type   = lfa.key
          lambda_arn   = lfa.value.lambda_arn
          include_body = lookup(lfa.value, "include_body", null)
        }
      }
    }
  }
}

resource "aws_route53_record" "_" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution._.domain_name
    zone_id                = aws_cloudfront_distribution._.hosted_zone_id
    evaluate_target_health = false
  }
}
