locals {
  extensions = jsondecode(file("${path.module}/data/extensions.json"))
}

