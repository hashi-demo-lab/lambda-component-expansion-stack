# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "invoke_url" {
  description = "URL for invoking the Lambda function via API Gateway"
  value       = aws_apigatewayv2_stage.lambda.invoke_url
}

output "api_id" {
  description = "The ID of the API Gateway"
  value       = aws_apigatewayv2_api.lambda.id
}

output "api_endpoint" {
  description = "The API Gateway endpoint"
  value       = aws_apigatewayv2_api.lambda.api_endpoint
}

output "log_group_name" {
  description = "CloudWatch Log Group name for the API Gateway"
  value       = aws_cloudwatch_log_group.api_gw.name
}
