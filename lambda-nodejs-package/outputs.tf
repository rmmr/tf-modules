output "output_file" {
  value = data.null_data_source._.outputs["filename"]
}

output "triggers" {
  value = null_resource._.triggers
}
