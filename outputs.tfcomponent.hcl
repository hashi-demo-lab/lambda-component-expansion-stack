# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# ==============================================================================
# API Gateway Endpoints
# ==============================================================================

output "api_endpoints" {
  type        = map(string)
  description = "API Gateway invoke URLs for each region"
  value = {
    for region, api in component.api_gateway : 
    region => api.invoke_url
  }
}

output "api_endpoint_instructions" {
  type        = string
  description = "Instructions for testing the API endpoints"
  value       = "Add /hello?name=YourName to any endpoint URL to test the Lambda function"
}

# ==============================================================================
# Lambda Functions
# ==============================================================================

output "lambda_function_names" {
  type        = map(string)
  description = "Lambda function names deployed in each region"
  value = {
    for region, lambda in component.lambda : 
    region => lambda.function_name
  }
}

output "lambda_function_arns" {
  type        = map(string)
  description = "Lambda function ARNs for each region"
  value = {
    for region, lambda in component.lambda : 
    region => lambda.function_arn
  }
}

# ==============================================================================
# S3 Buckets
# ==============================================================================

output "s3_bucket_names" {
  type        = map(string)
  description = "S3 bucket names storing Lambda deployment packages in each region"
  value = {
    for region, s3 in component.s3 : 
    region => s3.bucket_name
  }
}

output "s3_bucket_arns" {
  type        = map(string)
  description = "S3 bucket ARNs for each region"
  value = {
    for region, s3 in component.s3 : 
    region => s3.bucket_arn
  }
}

# ==============================================================================
# Monitoring & Observability
# ==============================================================================

output "cloudwatch_log_groups" {
  type = object({
    lambda      = map(string)
    api_gateway = map(string)
  })
  description = "CloudWatch Log Groups for Lambda functions and API Gateways"
  value = {
    lambda = {
      for region, lambda in component.lambda : 
      region => lambda.log_group_name
    }
    api_gateway = {
      for region, api in component.api_gateway : 
      region => api.log_group_name
    }
  }
}

output "aws_console_links" {
  type = object({
    lambda      = map(string)
    api_gateway = map(string)
    s3          = map(string)
  })
  description = "Direct links to AWS Console for each resource"
  value = {
    lambda = {
      for region, lambda in component.lambda : 
      region => "https://${region}.console.aws.amazon.com/lambda/home?region=${region}#/functions/${lambda.function_name}"
    }
    api_gateway = {
      for region, api in component.api_gateway : 
      region => "https://${region}.console.aws.amazon.com/apigateway/main/apis/${api.api_id}/resources?region=${region}"
    }
    s3 = {
      for region, s3 in component.s3 : 
      region => "https://s3.console.aws.amazon.com/s3/buckets/${s3.bucket_name}?region=${region}"
    }
  }
}

# ==============================================================================
# Deployment Summary
# ==============================================================================

output "deployment_summary" {
  type        = string
  description = "Summary of the deployed serverless API infrastructure"
  value       = <<-EOT
    Serverless API Stack Deployed Successfully
    ==========================================
    
    Regions: ${join(", ", keys(component.api_gateway))}
    Components: S3, Lambda, API Gateway
    
    Test your API endpoints:
    ${join("\n    ", [for region, api in component.api_gateway : "${region}: ${api.invoke_url}/hello?name=Demo"])}
  EOT
}
