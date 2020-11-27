output "triggers" {
  value = module.build.triggers
}

output "output_dir" {
  value = module.build.output_dir
}

output "serverless_next_dir" {
  value = "${module.build.output_dir}/.serverless_next"
}

output "next_dir" {
  value = "${module.build.output_dir}/.next"
}

output "default_lambda_package" {
  value = data.archive_file.default_lambda_package.output_path
}

output "api_lambda_package" {
  value = data.archive_file.api_lambda_package.output_path
}