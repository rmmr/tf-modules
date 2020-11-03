output "output_dir" {
  value = data.null_data_source._.outputs["output_dir"]
}

output "triggers" {
  value = null_resource._.triggers
}
