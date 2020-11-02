locals {
  runtime                 = "nodejs${var.nodejs_version}"
  routes_manifest         = fileexists(module.build.routes_manifest_file) ? jsondecode(file(module.build.routes_manifest_file)) : null
  default_lambda_manifest = fileexists(module.build.default_lambda_manifest_file) ? jsondecode(file(module.build.default_lambda_manifest_file)) : null
  api_lambda_manifest     = fileexists(module.build.api_lambda_manifest_file) ? jsondecode(file(module.build.api_lambda_manifest_file)) : null
  pages_manifest          = fileexists(module.build.pages_manifest_file) ? jsondecode(file(module.build.pages_manifest_file)) : null
  prerender_manifest      = fileexists(module.build.prerender_manifest_file) ? jsondecode(file(module.build.prerender_manifest_file)) : null
  base_path               = local.routes_manifest != null ? (length(local.routes_manifest.basePath) > 0 ? "${substr(local.routes_manifest.basePath, 1, length(local.routes_manifest.basePath))}/" : "") : ""

  next_static_paths = {
    for filename in fileset(module.build.next_dir, "static/**") :
    "_next/${filename}" => "${module.build.next_dir}/${filename}"
  }

  static_pages_paths = local.pages_manifest != null ? {
    for pageFile in values(local.pages_manifest) :
    "static-pages/${replace(pageFile, "pages/", "")}" => "${module.build.next_dir}/serverless/${pageFile}"
    if length(pageFile) > 5 && substr(pageFile, length(pageFile) - 5, 5) == ".html"
  } : null

  prerender_pages_json_paths = local.prerender_manifest != null ? {
    for key in keys(local.prerender_manifest.routes) :
    substr(local.prerender_manifest.routes[key].dataRoute, 1, length(local.prerender_manifest.routes[key].dataRoute) - 1)
    => "${
      module.build.next_dir}/serverless/pages/${substr(key, length(key) - 1, 1) == "/"
      ? "${trimprefix(key, "/")}index.json"
      : "${trimprefix(key, "/")}.json"
    }"
  } : null

  prerender_pages_html_paths = local.prerender_manifest != null ? {
    for key in keys(local.prerender_manifest.routes) :
    "static-pages/${
      substr(key, length(key) - 1, 1) == "/"
      ? "${trimprefix(key, "/")}index.html"
      : "${trimprefix(key, "/")}.html"
    }"
    => "${module.build.next_dir}/serverless/pages/${
      substr(key, length(key) - 1, 1) == "/"
      ? "${trimprefix(key, "/")}index.html"
      : "${trimprefix(key, "/")}.html"
    }"
  } : null

  assets_dir = "${module.build.output_dir}/.serverless_next/assets"

  public_paths = {
    for filename in fileset(local.assets_dir, "public/**") :
    filename => "${local.assets_dir}/${filename}"
  }
}

module "s3_objects" {
  source = "../s3-sync"
  bucket = module.site.bucket
  objects = {
    for path, filename in merge(
      local.next_static_paths,
      local.static_pages_paths,
      local.prerender_pages_json_paths,
      local.prerender_pages_html_paths,
      local.public_paths
    ) :
    "${local.base_path}${path}" => {
      source = filename
      acl    = "public-read"
    }
  }
}

module "build" {
  source = "./modules/sls-next-build"

  source_dir         = var.source_dir
  content_dir        = var.content_dir
  output_dir         = var.build_dir
  extra_dependencies = var.extra_dependencies
  npm_config         = var.npm_config
  env                = var.env
}


module "default_lambda" {
  source = "../lambda"

  function_name = "${var.name}-default"
  handler       = "index.handler"
  runtime       = local.runtime
  memory_size   = var.memory_size
  timeout       = 30
  edge          = true
  publish       = true

  allowed_actions = {
    AllowS3Access = {
      actions   = ["*"]
      resources = ["*"]
    }
  }

  filename         = module.build.default_lambda_package_file
  source_code_hash = fileexists(module.build.default_lambda_package_file) ? filebase64sha256(module.build.default_lambda_package_file) : null

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

  filename         = module.build.api_lambda_package_file
  source_code_hash = fileexists(module.build.api_lambda_package_file) ? filebase64sha256(module.build.api_lambda_package_file) : null

  tags = var.tags
}


module "site" {
  source      = "../cloudfront-site"
  zone_id     = var.zone_id
  domain_name = var.domain_name
  bucket_name = var.bucket_name

  cache_behavior = {
    default = {
      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 31536000

      query_string    = true
      cookies_forward = "all"
      compress        = true
      headers         = var.custom_headers

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

      query_string    = true
      cookies_forward = "all"
      headers         = var.custom_headers

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

