output "types" {
  value = {
    for file in var.files :
    file => lookup(local.extensions, ".${split(".", file, )[length(split(".", file)) - 1]}", null)
  }
}
