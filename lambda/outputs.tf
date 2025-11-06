# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.hello_world.function_name
}

output "function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.hello_world.arn
}

output "invoke_arn" {
  description = "The invocation ARN of the function"
  value       = aws_lambda_function.hello_world.invoke_arn
}

output "log_group_name" {
  description = "CloudWatch Log Group name for the Lambda function"
  value       = aws_cloudwatch_log_group.hello_world.name
}
