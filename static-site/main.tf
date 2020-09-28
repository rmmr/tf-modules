provider "aws" {
  alias  = "us"
  region = "us-east-1"
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> v2.0"

  domain_name = var.domain_name
  zone_id     = var.zone_id

  tags = var.tags

  providers = {
    aws = aws.us
  }
}

resource "aws_s3_bucket" "_" {
  bucket = var.bucket_name
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = var.tags
}

resource "aws_cloudfront_distribution" "_" {
  origin {
    domain_name = aws_s3_bucket._.bucket_domain_name
    origin_id   = "${var.domain_name}-origin"
  }

  enabled             = true
  aliases             = [var.domain_name]
  price_class         = "PriceClass_100"
  default_root_object = "index.html"
  default_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH",
    "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.domain_name}-origin"
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 1000
    max_ttl                = 86400
  }

  custom_error_response {
    error_caching_min_ttl = 1000
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

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
