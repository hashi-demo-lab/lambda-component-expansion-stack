# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# ==============================================================================
# OIDC Identity Tokens for AWS Authentication
# ==============================================================================
identity_token "aws" {
  audience = ["terraform-stacks-private-preview"]
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
    regions            = ["ap-southeast-2"]  # Sydney
    role_arn           = "arn:aws:iam::258850230659:role/tfstacks-role"
    aws_identity_token = identity_token.aws.jwt
  }
  deployment_group = deployment_group.development
  
  # flip this on only when you intend to destroy
  destroy = true
}

deployment "test" {
  inputs = {
    regions            = ["ap-southeast-2"]  # Sydney
    role_arn           = "arn:aws:iam::258850230659:role/tfstacks-role"
    aws_identity_token = identity_token.aws.jwt
  }
  deployment_group = deployment_group.test

  # flip this on only when you intend to destroy
  destroy = true
}

deployment "staging" {
  inputs = {
    regions            = ["ap-southeast-2", "ap-southeast-1"]  # Sydney, Singapore
    role_arn           = "arn:aws:iam::258850230659:role/tfstacks-role"
    aws_identity_token = identity_token.aws.jwt
  }
  deployment_group = deployment_group.staging

  # flip this on only when you intend to destroy
  destroy = true
}

deployment "production" {
  inputs = {
    regions            = ["ap-southeast-2", "ap-southeast-1"]  # Sydney, Singapore
    role_arn           = "arn:aws:iam::258850230659:role/tfstacks-role"
    aws_identity_token = identity_token.aws.jwt
  }
  deployment_group = deployment_group.production

  # flip this on only when you intend to destroy
  destroy = true
}