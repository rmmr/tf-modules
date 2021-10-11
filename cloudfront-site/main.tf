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

  subject_alternative_names = tolist(var.aliases)

  tags = var.tags
}

resource "aws_s3_bucket" "_" {
  bucket = var.bucket_name != null ? var.bucket_name : replace(var.domain_name, ".", "-")
  acl    = "public-read"

  dynamic "website" {
    for_each = var.index_document != null ? [true] : []

    content {
      index_document = var.index_document
    }
  }

  tags = var.tags
}

resource "aws_cloudfront_origin_access_identity" "_" {

}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket._.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity._.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "_" {
  bucket = aws_s3_bucket._.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_cloudfront_distribution" "_" {
  origin {
    // workaround for https://github.com/terraform-providers/terraform-provider-aws/issues/15102
    domain_name = "${aws_s3_bucket._.bucket}.s3.${data.aws_region.current.name}.amazonaws.com"
    origin_id   = local.s3_origin_id
    origin_path = var.bucket_path

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity._.cloudfront_access_identity_path
    }
  }

  enabled     = var.enabled
  aliases     = concat([var.domain_name], tolist(var.aliases))
  price_class = var.price_class

  default_root_object = var.index_document

  viewer_certificate {
    acm_certificate_arn      = module.acm.this_acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_response
    content {
      error_code = custom_error_response.value["error_code"]

      response_code         = lookup(custom_error_response.value, "response_code", null)
      response_page_path    = lookup(custom_error_response.value, "response_page_path", null)
      error_caching_min_ttl = lookup(custom_error_response.value, "error_caching_min_ttl", null)
    }
  }

  restrictions {
    dynamic "geo_restriction" {
      for_each = [var.geo_restriction]

      content {
        restriction_type = lookup(geo_restriction.value, "restriction_type", "none")
        locations        = lookup(geo_restriction.value, "locations", [])
      }
    }
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

resource "aws_route53_record" "alias" {
  for_each = var.aliases

  zone_id = var.zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution._.domain_name
    zone_id                = aws_cloudfront_distribution._.hosted_zone_id
    evaluate_target_health = false
  }
}
