locals {
  build_dir      = "/tmp/build"
  abs_output_dir = abspath(var.output_dir)
  abs_source_dir = abspath(var.source_dir)
  abs_module_dir = abspath(path.module)
  package        = fileexists("${local.abs_source_dir}/package.json") ? jsondecode(file("${local.abs_source_dir}/package.json")) : null
  extra_dependencies = merge(
    {
      "@sls-next/lambda-at-edge" : "1.7.0-alpha.6"
    },
    local.package != null ? lookup(local.package, "peerDependencies", {}) : {},
    var.extra_dependencies
  )

  npmrc = var.npm_config
}

data "null_data_source" "_" {
  inputs = {
    id         = null_resource._.id
    output_dir = local.abs_output_dir
  }
}

resource "null_resource" "_" {
  triggers = {
    // This trigger will cause this resource to be initially applied twice,
    // however it ensures that the build file will be created if not present.
    output_files_exist       = fileexists("${local.abs_output_dir}/default-lambda.zip") && fileexists("${local.abs_output_dir}/api-lambda.zip") ? "true" : "false"
    package_file_has_changed = fileexists("${local.abs_source_dir}/package.json") ? filemd5("${local.abs_source_dir}/package.json") : null
  }

  provisioner "local-exec" {
    command = <<EOF
    mkdir -p ${local.abs_output_dir}
    docker run \
        ${join(" ", [for k, v in var.env : "-e ${k}=${v}"])}\
        -v ${local.abs_source_dir}:/var/task \
        -v ${local.abs_module_dir}/data:/var/tf-data \
        -v ${local.abs_output_dir}:/var/output \
        "lambci/lambda:build-nodejs12.x" \
        /bin/bash -c "
            set -e; \
            cd /var/output && shopt -s dotglob && eval 'rm -r ./*' && shopt -u dotglob; \
            echo \"${local.npmrc}\" > ~/.npmrc; \
            mkdir -p /tmp/build; \
            cd /var/task; \
            shopt -s extglob && eval 'cp -r !(node_modules|.next|.env) /tmp/build/' && shopt -u extglob; \
            cp -r /var/tf-data/. /tmp/build/; \
            cd /tmp/build; \
            npm install; \
            npm install ${join(" ", [for k, v in local.extra_dependencies : (v == true ? k : "${k}@${v}") if v != false])}; \
            node --unhandled-rejections=strict builder.js; \
            cd /tmp/build/; \
            cp -r .serverless_next /var/output/.serverless_next; \
            cp -r .next /var/output/.next; \
            cd /tmp/build/.serverless_next/default-lambda; \
            zip -r9 /var/output/default-lambda.zip .; \
            cd /tmp/build/.serverless_next/api-lambda; \
            zip -r9 /var/output/api-lambda.zip .; \
            exit;"
    EOF
  }
}