# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# ==============================================================================
# OIDC Identity Tokens for AWS Authentication
# ==============================================================================
identity_token "aws" {
  audience = ["aws.workload.identity"]
}

# ==============================================================================
# Auto-Approval Rules for Deployment Groups
# ==============================================================================

# Development: Allow up to 20 changes for rapid iteration
deployment_auto_approve "dev_allow_changes" {
  check {
    condition = context.plan.changes.total <= 20
    reason    = "Development environment allows up to 20 changes for rapid iteration"
  }
}

# Test: Moderate guardrails - no destroys, limited changes
deployment_auto_approve "test_safe_changes" {
  check {
    condition = context.plan.changes.remove == 0
    reason    = "Test environment does not allow resource destruction (${context.plan.changes.remove} resources would be destroyed)"
  }
  check {
    condition = context.plan.changes.total <= 10
    reason    = "Test environment limits changes to 10 (${context.plan.changes.total} changes proposed)"
  }
}

# Staging: Strict guardrails - minimal changes only
deployment_auto_approve "staging_strict" {
  check {
    condition = context.plan.changes.remove == 0
    reason    = "Staging environment prohibits resource destruction (${context.plan.changes.remove} resources would be destroyed)"
  }
  check {
    condition = context.plan.changes.total <= 5
    reason    = "Staging environment allows maximum 5 changes (${context.plan.changes.total} changes proposed)"
  }
}

# Production: Most restrictive - very small changes, no destroys
deployment_auto_approve "production_critical" {
  check {
    condition = context.plan.changes.remove == 0
    reason    = "Production environment absolutely prohibits resource destruction (${context.plan.changes.remove} resources would be destroyed)"
  }
  check {
    condition = context.plan.changes.total <= 3
    reason    = "Production environment allows maximum 3 changes per deployment (${context.plan.changes.total} changes proposed)"
  }
  check {
    condition = context.success == true
    reason    = "Production deployment failed and requires manual intervention"
  }
}

# ==============================================================================
# Deployment Groups
# ==============================================================================

deployment_group "development" {
  auto_approve_checks = [
    deployment_auto_approve.dev_allow_changes
  ]
}

deployment_group "test" {
  auto_approve_checks = [
    deployment_auto_approve.test_safe_changes
  ]
}

deployment_group "staging" {
  auto_approve_checks = [
    deployment_auto_approve.staging_strict
  ]
}

deployment_group "production" {
  auto_approve_checks = [
    deployment_auto_approve.production_critical
  ]
}

# ==============================================================================
# Environment Deployments
# ==============================================================================

deployment "dev" {
  inputs = {
    environment        = "dev"
    regions            = ["us-east-1"]
    role_arn           = "<Set to your development AWS account IAM role ARN>"
    aws_identity_token = identity_token.aws.jwt
    lambda_memory_mb   = 128
    log_retention_days = 7
    default_tags = {
      Stack       = "serverless-api-stack"
      Environment = "Development"
      ManagedBy   = "Terraform-Stacks"
      CostCenter  = "Engineering"
    }
  }
  deployment_group = deployment_group.development
}

deployment "test" {
  inputs = {
    environment        = "test"
    regions            = ["us-east-1"]
    role_arn           = "<Set to your test AWS account IAM role ARN>"
    aws_identity_token = identity_token.aws.jwt
    lambda_memory_mb   = 256
    log_retention_days = 14
    default_tags = {
      Stack       = "serverless-api-stack"
      Environment = "Test"
      ManagedBy   = "Terraform-Stacks"
      CostCenter  = "Engineering"
    }
  }
  deployment_group = deployment_group.test
}

deployment "staging" {
  inputs = {
    environment        = "staging"
    regions            = ["us-east-1", "us-west-2"]
    role_arn           = "<Set to your staging AWS account IAM role ARN>"
    aws_identity_token = identity_token.aws.jwt
    lambda_memory_mb   = 512
    log_retention_days = 30
    default_tags = {
      Stack       = "serverless-api-stack"
      Environment = "Staging"
      ManagedBy   = "Terraform-Stacks"
      CostCenter  = "Engineering"
    }
  }
  deployment_group = deployment_group.staging
}

deployment "production" {
  inputs = {
    environment        = "production"
    regions            = ["us-east-1", "us-west-2", "eu-west-1"]
    role_arn           = "<Set to your production AWS account IAM role ARN>"
    aws_identity_token = identity_token.aws.jwt
    lambda_memory_mb   = 1024
    log_retention_days = 90
    default_tags = {
      Stack       = "serverless-api-stack"
      Environment = "Production"
      ManagedBy   = "Terraform-Stacks"
      CostCenter  = "Production-Services"
      Compliance  = "Required"
    }
  }
  deployment_group = deployment_group.production
}

