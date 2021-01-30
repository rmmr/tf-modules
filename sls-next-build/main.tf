locals {
  env = merge(
    {
      MINIFY_HANDLERS : var.minify_handlers ? 1 : 0,
      USE_SERVERLESS_TRACE_TARGETS : var.use_serverless_trace_targets ? 1 : 0,
      DOMAIN_REDIRECTS : jsonencode(var.domain_redirects)
    },
  var.env)
  local_build_cmd  = <<EOF
set -e;
NODE_PATH="./node_modules" node ${abspath(path.root)}/${path.module}/data/builder.js;
EOF
  docker_build_cmd = <<EOF
docker run \
  ${join(" ", [for k, v in local.env : "-e ${k}=${v}"])}\
  -v ${var.source_dir}:/var/task \
  -v ${abspath(path.root)}/${path.module}/data/builder.js:/tmp/builder.js \
  "lambci/lambda:build-nodejs12.x" \
  /bin/bash -c "
    set -e; \
    NODE_PATH="./node_modules" node /tmp/builder.js;"
EOF
}


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
  cmd        = var.use_docker ? local.local_build_cmd : local.docker_build_cmd
  env        = local.env
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
