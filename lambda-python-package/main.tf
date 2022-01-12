locals {
  build_dir       = "/tmp/build"
  abs_output_file = abspath(var.output_file)
  abs_source_dir  = abspath(var.source_dir)
}

data "null_data_source" "_" {
  inputs = {
    id       = null_resource._.id
    filename = local.abs_output_file
  }
}

resource "null_resource" "_" {
  triggers = {
    setup_file_has_changed        = fileexists("${local.abs_source_dir}/setup.py") ? filemd5("${local.abs_source_dir}/setup.py") : null
    requirements_file_has_changed = fileexists("${local.abs_source_dir}/requirements.txt") ? filemd5("${local.abs_source_dir}/requirements.txt") : null
    env_has_changed               = sha256(jsonencode(var.env))
  }

  provisioner "local-exec" {
    command = <<EOF
    mkdir -p ${dirname(local.abs_output_file)}
    docker run \
        --rm \
        ${join(" ", [for k, v in var.env : "-e ${k}=${v}"])}\
        -v ${local.abs_source_dir}:/var/task \
        "lambci/lambda:build-python3.8" \
        /bin/sh -c "
            mkdir -p /tmp/build; \
            ${fileexists("${local.abs_source_dir}/setup.py") ? "pip install . -t /tmp/build > /dev/null 2>&1;" : ""}\
            ${fileexists("${local.abs_source_dir}/requirements.txt") ? "pip install -r requirements.txt -t /tmp/build > /dev/null 2>&1;" : ""}\
            rm -rf /tmp/build/botocore /tmp/build/boto3; \
            cd /tmp/build && zip -r9  - .; \
            exit;" > ${local.abs_output_file}
    EOF
  }
}
