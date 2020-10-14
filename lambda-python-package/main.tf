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
    // Will cause this resource to be applied twice in order to settle. But prevents file from not existing.
    output_file_hash              = fileexists(local.abs_output_file) ? filemd5(local.abs_output_file) : null
    setup_file_has_changed        = fileexists("${local.abs_source_dir}/setup.py") ? filemd5("${local.abs_source_dir}/setup.py") : null
    requirements_file_has_changed = fileexists("${local.abs_source_dir}/requirements.txt") ? filemd5("${local.abs_source_dir}/requirements.txt") : null
  }

  provisioner "local-exec" {
    command = <<EOF
    mkdir -p ${dirname(local.abs_output_file)}
    docker run \
        ${join(" ", [for k, v in var.env : "-e ${k}=${v}"])}\
        -v ${local.abs_source_dir}:/var/task \
        "lambci/lambda:build-python3.7" \
        /bin/sh -c "
            ${fileexists("${local.abs_source_dir}/setup.py") ? "pip install . -t /tmp/build > /dev/null 2>&1;" : ""}\
            ${fileexists("${local.abs_source_dir}/requirements.txt") ? "pip install -r requirements.txt -t /tmp/build > /dev/null 2>&1;" : ""}\
            cd /tmp/build && zip -r9  - .; \
            exit;" > ${local.abs_output_file}
    EOF
  }
}
