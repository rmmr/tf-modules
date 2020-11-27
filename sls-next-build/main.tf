module "build" {
  source = "../build"
  triggers = {
    package_file_has_changed = fileexists("${var.source_dir}/package.json") ? filemd5("${var.source_dir}/package.json") : null
  }

  output_dir = var.source_dir
  cwd        = var.source_dir
  cmd        = <<EOF
  npm install --no-package-lock --no-save @sls-next/lambda-at-edge@1.7.0 klaw@3.0.0 
  NODE_PATH="./node_modules" node ${abspath(path.root)}/${path.module}/data/builder.js
  EOF
  env = merge(
    {
      MINIFY_HANDLERS : var.minify_handlers ? 1 : 0,
      USE_SERVERLESS_TRACE_TARGETS : var.use_serverless_trace_targets ? 1 : 0
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
