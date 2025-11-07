# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

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


