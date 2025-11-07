# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# ==============================================================================
# Environment Configuration
# ==============================================================================

variable "environment" {
  type        = string
  description = "Environment name (dev, test, staging, production)"
  
  validation {
    condition     = contains(["dev", "test", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, test, staging, production"
  }
}

# ==============================================================================
# Regional Deployment Configuration
# ==============================================================================

variable "regions" {
  type        = set(string)
  description = "AWS regions to deploy serverless API infrastructure. Each region will receive: S3 bucket, Lambda function, and API Gateway"
  
  validation {
    condition     = length(var.regions) > 0 && length(var.regions) <= 10
    error_message = "Must specify between 1 and 10 AWS regions for deployment"
  }
  
  validation {
    condition = alltrue([
      for region in var.regions : 
      can(regex("^(us|eu|ap|sa|ca|me|af)-(north|south|east|west|central|northeast|southeast|southwest)-[1-3]$", region))
    ])
    error_message = "All regions must be valid AWS region identifiers (e.g., us-east-1, eu-west-2)"
  }
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
  
  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", var.role_arn))
    error_message = "Role ARN must be a valid AWS IAM role ARN format: arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
  }
}

# ==============================================================================
# Lambda Configuration
# ==============================================================================

variable "lambda_memory_mb" {
  type        = number
  description = "Memory allocation for Lambda function in MB. Higher memory also increases CPU allocation"
  default     = 128
  
  validation {
    condition     = var.lambda_memory_mb >= 128 && var.lambda_memory_mb <= 10240
    error_message = "Lambda memory must be between 128 MB and 10,240 MB"
  }
  
  validation {
    condition     = var.lambda_memory_mb % 64 == 0
    error_message = "Lambda memory must be a multiple of 64 MB"
  }
}

# ==============================================================================
# Monitoring Configuration
# ==============================================================================

variable "log_retention_days" {
  type        = number
  description = "CloudWatch Logs retention period in days. Longer retention increases storage costs"
  default     = 30
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention must be one of the valid CloudWatch Logs retention periods"
  }
}

# ==============================================================================
# Tagging Configuration
# ==============================================================================

variable "default_tags" {
  type        = map(string)
  description = "Default tags applied to all AWS resources for cost allocation, compliance, and resource management"
  default     = {}
  
  validation {
    condition     = length(var.default_tags) <= 50
    error_message = "AWS supports a maximum of 50 tags per resource"
  }
  
  validation {
    condition = alltrue([
      for key, value in var.default_tags : 
      can(regex("^[a-zA-Z0-9+\\-=._:/@\\s]{1,128}$", key)) && 
      can(regex("^[a-zA-Z0-9+\\-=._:/@\\s]{0,256}$", value))
    ])
    error_message = "Tag keys must be 1-128 characters and values must be 0-256 characters, using allowed AWS tag characters"
  }
}
