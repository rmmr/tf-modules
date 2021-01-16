locals {
  runtime = "nodejs${var.nodejs_version}"

  default_lambda_manifest_file = "${var.serverless_next_dir}/default-lambda/manifest.json"
  default_lambda_manifest      = fileexists(local.default_lambda_manifest_file) ? jsondecode(file(local.default_lambda_manifest_file)) : null

  api_lambda_manifest_file = "${var.serverless_next_dir}/api-lambda/manifest.json"
  api_lambda_manifest      = fileexists(local.api_lambda_manifest_file) ? jsondecode(file(local.api_lambda_manifest_file)) : null

  routes_manifest_file = "${var.next_dir}/routes-manifest.json"
  routes_manifest      = fileexists(local.routes_manifest_file) ? jsondecode(file(local.routes_manifest_file)) : null

  pages_manifest_file = "${var.next_dir}/serverless/pages-manifest.json"
  pages_manifest      = fileexists(local.pages_manifest_file) ? jsondecode(file(local.pages_manifest_file)) : null

  prerender_manifest_file = "${var.next_dir}/prerender-manifest.json"
  prerender_manifest      = fileexists(local.prerender_manifest_file) ? jsondecode(file(local.prerender_manifest_file)) : null

  base_path = local.routes_manifest != null ? (length(local.routes_manifest.basePath) > 0 ? "${substr(local.routes_manifest.basePath, 1, length(local.routes_manifest.basePath))}/" : "") : ""

  build_id = local.default_lambda_manifest != null ? local.default_lambda_manifest.buildId : null

  next_static_paths = {
    for filename in fileset(var.next_dir, "static/**") :
    "_next/${filename}" => "${var.next_dir}/${filename}"
  }

  static_pages_paths = local.pages_manifest != null ? {
    for pageFile in values(local.pages_manifest) :
    "static-pages/${local.build_id}/${replace(pageFile, "pages/", "")}" => "${var.next_dir}/serverless/${pageFile}"
    if length(pageFile) > 5 && substr(pageFile, length(pageFile) - 5, 5) == ".html"
  } : null

  prerender_pages_json_paths = local.prerender_manifest != null ? {
    for key in keys(local.prerender_manifest.routes) :
    substr(local.prerender_manifest.routes[key].dataRoute, 1, length(local.prerender_manifest.routes[key].dataRoute) - 1)
    => "${
      var.next_dir}/serverless/pages/${substr(key, length(key) - 1, 1) == "/"
      ? "${trimprefix(key, "/")}index.json"
      : "${trimprefix(key, "/")}.json"
    }"
  } : null

  prerender_pages_html_paths = local.prerender_manifest != null ? {
    for key in keys(local.prerender_manifest.routes) :
    "static-pages/${local.build_id}/${
      substr(key, length(key) - 1, 1) == "/"
      ? "${trimprefix(key, "/")}index.html"
      : "${trimprefix(key, "/")}.html"
    }"
    => "${var.next_dir}/serverless/pages/${
      substr(key, length(key) - 1, 1) == "/"
      ? "${trimprefix(key, "/")}index.html"
      : "${trimprefix(key, "/")}.html"
    }"
  } : null

  assets_dir = "${var.serverless_next_dir}/assets"

  public_paths = {
    for filename in fileset(local.assets_dir, "public/**") :
    filename => "${local.assets_dir}/${filename}"
  }

  files = merge(
    local.next_static_paths,
    local.static_pages_paths,
    local.prerender_pages_json_paths,
    local.prerender_pages_html_paths,
    local.public_paths
  )
}

module "default_lambda" {
  source = "../lambda"

  function_name = "${var.name}-default"
  handler       = "index.handler"
  runtime       = local.runtime
  memory_size   = var.memory_size
  timeout       = var.timeout
  edge          = true
  publish       = true

  allowed_actions = {
    AllowS3Access = {
      actions   = ["*"]
      resources = ["*"]
    }
  }

  filename         = var.default_lambda_package
  source_code_hash = fileexists(var.default_lambda_package) ? filebase64sha256(var.default_lambda_package) : null

  tags = var.tags
}

module "api_lambda" {
  source = "../lambda"

  function_name = "${var.name}-api"
  handler       = "index.handler"
  runtime       = local.runtime
  memory_size   = var.memory_size
  timeout       = var.timeout
  edge          = true
  publish       = true

  allowed_actions = {
    AllowS3Access = {
      actions   = ["*"]
      resources = ["*"]
    }
  }

  filename         = var.api_lambda_package
  source_code_hash = fileexists(var.api_lambda_package) ? filebase64sha256(var.api_lambda_package) : null

  tags = var.tags
}


module "mime" {
  source = "../mime"
  files  = toset(values(local.files))
}

resource "aws_s3_bucket_object" "files" {
  for_each = local.files

  bucket       = module.site.bucket
  key          = each.key
  source       = each.value
  acl          = "public-read"
  etag         = filemd5(each.value)
  content_type = module.mime.types[each.value]
}

module "site" {
  source      = "../cloudfront-site"
  zone_id     = var.zone_id
  domain_name = var.domain_name
  bucket_name = var.bucket_name
  aliases     = var.aliases

  cache_behavior = {
    default = {
      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 31536000

      query_string           = true
      cookies_forward        = "all"
      compress               = true
      headers                = var.custom_headers
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = [
        "HEAD",
        "DELETE",
        "POST",
        "GET",
        "OPTIONS",
        "PUT",
        "PATCH"
      ]

      lambda_function_association = {
        origin-request = {
          lambda_arn = module.default_lambda.this_lambda_function_qualified_arn
        }
        origin-response = {
          lambda_arn = module.default_lambda.this_lambda_function_qualified_arn
        }
      }
    }

    next_static = {
      path_pattern = "${local.base_path}_next/static/*"

      min_ttl     = 0
      default_ttl = 86400
      max_ttl     = 31536000

      query_string    = false
      cookies_forward = "none"

    }

    static = {
      path_pattern = "${local.base_path}static/*"

      min_ttl     = 0
      default_ttl = 86400
      max_ttl     = 31536000

      query_string    = false
      cookies_forward = "none"
    }

    api = {
      path_pattern = "${local.base_path}api/*"

      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 31536000

      query_string           = true
      cookies_forward        = "all"
      headers                = var.custom_headers
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = [
        "HEAD",
        "DELETE",
        "POST",
        "GET",
        "OPTIONS",
        "PUT",
        "PATCH"
      ]

      lambda_function_association = {
        origin-request = {
          lambda_arn   = module.api_lambda.this_lambda_function_qualified_arn
          include_body = true
        }
      }
    }

    next_data = {
      path_pattern = "${local.base_path}_next/data/*"

      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 31536000

      query_string           = true
      cookies_forward        = "all"
      headers                = var.custom_headers
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["HEAD", "GET"]

      lambda_function_association = {
        origin-request = {
          lambda_arn = module.default_lambda.this_lambda_function_qualified_arn
        }
        origin-response = {
          lambda_arn = module.default_lambda.this_lambda_function_qualified_arn
        }
      }
    }
  }

  tags = var.tags
}

