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
    setup_file_has_changed = filemd5("${local.abs_source_dir}/setup.py")
  }

  provisioner "local-exec" {
    command = <<EOF
    mkdir -p ${dirname(local.abs_output_file)}
    docker run \
        -v ${local.abs_source_dir}:/var/task \
        "lambci/lambda:build-python3.7" \
        /bin/sh -c "
            pip install . -t /tmp/build > /dev/null 2>&1; \
            cd /tmp/build && zip -r9  - .; \
            exit;" > ${local.abs_output_file}
    EOF
  }
}
