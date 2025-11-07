# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# ==============================================================================
# Environment Configuration
# ==============================================================================

variable "environment" {
  type        = string
  description = "Environment name (dev, test, staging, production)"
}

# ==============================================================================
# Regional Deployment Configuration
# ==============================================================================

variable "regions" {
  type        = set(string)
  description = "AWS regions to deploy serverless API infrastructure. Each region will receive: S3 bucket, Lambda function, and API Gateway"
}

# ==============================================================================
# Authentication Configuration
# ==============================================================================

variable "aws_identity_token" {
  type        = string
  description = "OIDC identity token for AWS authentication via Web Identity"
  ephemeral   = true
  sensitive   = true
}

variable "role_arn" {
  type        = string
  description = "ARN of the IAM role to assume for AWS operations. Must have permissions for S3, Lambda, API Gateway, CloudWatch, and IAM"
  sensitive   = true
}

# ==============================================================================
# Lambda Configuration
# ==============================================================================

variable "lambda_memory_mb" {
  type        = number
  description = "Memory allocation for Lambda function in MB. Higher memory also increases CPU allocation"
  default     = 128
}

# ==============================================================================
# Monitoring Configuration
# ==============================================================================

variable "log_retention_days" {
  type        = number
  description = "CloudWatch Logs retention period in days. Longer retention increases storage costs"
  default     = 30
}

# ==============================================================================
# Tagging Configuration
# ==============================================================================

variable "default_tags" {
  type        = map(string)
  description = "Default tags applied to all AWS resources for cost allocation, compliance, and resource management"
  default     = {}
}

