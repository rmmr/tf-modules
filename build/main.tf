locals {
  abs_output_dir = abspath(var.output_dir)
}

data "null_data_source" "_" {
  inputs = {
    id         = null_resource._.id
    output_dir = local.abs_output_dir
  }
}

resource "null_resource" "_" {
  triggers = var.triggers

  provisioner "local-exec" {
    command     = var.cmd
    working_dir = var.cwd
    environment = var.env
  }
}
