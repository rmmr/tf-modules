locals {
  content_types = {
    svg = "image/svg+xml"
  }

  objects_with_content_types = {
    for key, object in var.objects :
    key => merge(
      object,
      lookup(object, "content_type", null) == null && lookup(object, "source", null) != null
      ? { content_type = lookup(local.content_types, split(".", object.source, )[length(split(".", object.source)) - 1], null) }
      : {},
    )
  }

  objects = {
    for key, object in local.objects_with_content_types :
    key => merge(
      object,
      { flags = merge(
        lookup(object, "acl", null) != null ? { acl = object.acl } : {},
        lookup(object, "content_type", null) != null ? { "content-type" = object.content_type } : {}
        )
      }
    )
  }
}

data "aws_region" "current" {

}

resource "null_resource" "_" {

  triggers = {
    bucket       = var.bucket
    region       = data.aws_region.current.name
    objects_hash = sha256(jsonencode(var.objects))
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
      AWS_REGION=${self.triggers.region} aws s3 rm s3://${self.triggers.bucket} --recursive
    EOF
  }

  provisioner "local-exec" {
    command = <<EOF
      echo "${join(";", [for key, object in local.objects : "aws s3 cp ${join(" ", [for k, v in object.flags : "--${k} ${v}"])} ${object.source} s3://${var.bucket}/${key}"])}" | AWS_REGION=${data.aws_region.current.name} parallel -j 10;
    EOF
  }
}
