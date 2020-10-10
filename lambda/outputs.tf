output "this_lambda_function_arn" {
  value = aws_lambda_function.this.arn
}

output "this_aws_iam_role_name" {
  value = aws_iam_role.lambda.name
}
