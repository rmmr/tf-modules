module "build" {
  source = "../build"
  triggers = {
    package_file_has_changed = fileexists("${var.source_dir}/package.json") ? filemd5("${var.source_dir}/package.json") : null
  }

  output_dir = "${var.source_dir}/dist"
  cwd        = var.source_dir
  cmd        = <<EOF
  npm install --dev @sls-next/lambda-at-edge@1.7.0 klaw@3.0.0
  node ${path.module}/data/builder.js
  EOF
  env = merge(
    {
      MINIFY_HANDLERS : var.minify_handlers ? 1 : 0,
      USE_SERVERLESS_TRACE_TARGETS : var.use_serverless_trace_targets ? 1 : 0
    },
  var.env)
}

data "archive_file" "default_lambda_package" {
  type        = "zip"
  source_path = "${var.source_dir}/.serverless_next/default-lambda"
  output_path = "${var.source_dir}/.serverless_next/default-lambda.zip"
}

data "archive_file" "api_lambda_package" {
  type        = "zip"
  source_path = "${var.source_dir}/.serverless_next/api-lambda"
  output_path = "${var.source_dir}/.serverless_next/api-lambda.zip"
}
