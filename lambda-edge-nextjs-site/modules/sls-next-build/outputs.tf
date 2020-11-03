output "output_dir" {
  value = data.null_data_source._.outputs["output_dir"]
}

output "serverless_next_dir" {
  value = "${data.null_data_source._.outputs["output_dir"]}/.serverless_next"
}

output "next_dir" {
  value = "${data.null_data_source._.outputs["output_dir"]}/.next"
}

output "default_lambda_package_file" {
  value = "${data.null_data_source._.outputs["output_dir"]}/default-lambda.zip"
}

output "api_lambda_package_file" {
  value = "${data.null_data_source._.outputs["output_dir"]}/api-lambda.zip"
}

output "default_lambda_manifest_file" {
  value = "${data.null_data_source._.outputs["output_dir"]}/.serverless_next/default-lambda/manifest.json"
}

output "api_lambda_manifest_file" {
  value = "${data.null_data_source._.outputs["output_dir"]}/.serverless_next/api-lambda/manifest.json"
}

output "routes_manifest_file" {
  value = "${data.null_data_source._.outputs["output_dir"]}/.next/routes-manifest.json"
}

output "pages_manifest_file" {
  value = "${data.null_data_source._.outputs["output_dir"]}/.next/serverless/pages-manifest.json"
}

output "prerender_manifest_file" {
  value = "${data.null_data_source._.outputs["output_dir"]}/.next/prerender-manifest.json"
}

output "triggers" {
  value = null_resource._.triggers
}
