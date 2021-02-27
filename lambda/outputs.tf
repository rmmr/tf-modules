output "this_lambda_function_arn" {
  value = aws_lambda_function.this.arn
}

output "this_lambda_function_qualified_arn" {
  value = aws_lambda_function.this.qualified_arn
}

output "this_lambda_function_name" {
  value = aws_lambda_function.this.name
}

output "this_aws_iam_role_name" {
  value = aws_iam_role.lambda.name
}
