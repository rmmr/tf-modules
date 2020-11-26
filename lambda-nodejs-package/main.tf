locals {
  build_dir       = "/tmp/build"
  abs_output_file = abspath(var.output_file)
  abs_source_dir  = abspath(var.source_dir)
  package         = fileexists("${local.abs_source_dir}/package.json") ? jsondecode(file("${local.abs_source_dir}/package.json")) : null
  extra_dependencies = merge(
    local.package != null ? lookup(local.package, "peerDependencies", {}) : {},
    var.extra_dependencies
  )

  npmrc = var.npm_config
}

data "null_data_source" "_" {
  inputs = {
    id       = null_resource._.id
    filename = local.abs_output_file
  }
}

resource "null_resource" "_" {
  triggers = {
    package_file_has_changed = fileexists("${local.abs_source_dir}/package.json") ? filemd5("${local.abs_source_dir}/package.json") : null
    env_has_changed          = sha256(jsonencode(var.env))
  }

  provisioner "local-exec" {
    command = <<EOF
    mkdir -p ${local.abs_output_dir}
    docker run \
        --rm \
        ${join(" ", [for k, v in var.env : "-e ${k}=${v}"])}\
        -v ${local.abs_source_dir}:/var/task \
        -v ${local.abs_output_dir}:/var/output \
        ${local.abs_content_dir != null ? "-v ${local.abs_content_dir}:/var/site-content" : ""} \
        "lambci/lambda:build-nodejs12.x" \
        /bin/bash -c "
            set -e; \
            cd /var/output && shopt -s dotglob && eval 'rm -r ./*' && shopt -u dotglob; \
            echo \"${local.npmrc}\" > ~/.npmrc; \
            mkdir -p /tmp/build; \
            cd /var/task; shopt -s extglob && eval 'cp -r !(node_modules|.next|.env) /tmp/build/' && shopt -u extglob; \
            ${local.abs_content_dir != null ? " cd /var/site-content; shopt -s extglob && eval 'cp -rf !(node_modules|.next|.env|.gitignore) /tmp/build/' && shopt -u extglob;" : ""} \
            cd /tmp/build; \
            npm install; \
            npm install ${join(" ", [for k, v in local.extra_dependencies : (v == true ? k : "${k}@${v}") if v != false])}; \
            ${var.custom_cmd} \
            cd /tmp/build/; \
            zip -r9 - .; \
            exit;"
    EOF
  }
}
