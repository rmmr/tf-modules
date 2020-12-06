module "build" {
  source = "../build"
  triggers = merge(
    {
      package_file_has_changed = fileexists("${var.source_dir}/package.json") ? filemd5("${var.source_dir}/package.json") : null
    },
    var.triggers
  )

  output_dir = var.source_dir
  cwd        = var.source_dir
  cmd        = <<EOF
  set -e
  node ${abspath(path.root)}/${path.module}/data/builder.js
  EOF
  env = merge(
    {
      MINIFY_HANDLERS : var.minify_handlers ? 1 : 0,
      USE_SERVERLESS_TRACE_TARGETS : var.use_serverless_trace_targets ? 1 : 0,
      DOMAIN_REDIRECTS : jsonencode(var.domain_redirects)
    },
  var.env)
}

data "archive_file" "default_lambda_package" {
  depends_on  = [module.build]
  type        = "zip"
  source_dir  = "${module.build.output_dir}/.serverless_next/default-lambda"
  output_path = "${module.build.output_dir}/.serverless_next/default-lambda.zip"
}

data "archive_file" "api_lambda_package" {
  depends_on  = [module.build]
  type        = "zip"
  source_dir  = "${module.build.output_dir}/.serverless_next/api-lambda"
  output_path = "${module.build.output_dir}/.serverless_next/api-lambda.zip"
}
