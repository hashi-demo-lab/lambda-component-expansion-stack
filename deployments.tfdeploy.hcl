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

# Development: Liberal auto-approval for rapid iteration
deployment_auto_approve "dev_rapid_iteration" {
  check {
    condition = context.plan.applyable
    reason    = "Plan must be applyable"
  }
  
  check {
    condition = context.plan.changes.total <= 50
    reason    = "Development allows up to 50 changes (current: ${context.plan.changes.total})"
  }
}

# Test: Moderate guardrails - no resource deletion
deployment_auto_approve "test_safe_changes" {
  check {
    condition = context.plan.applyable
    reason    = "Plan must be applyable"
  }
  
  check {
    condition = context.plan.changes.remove == 0
    reason    = "Test environment cannot auto-approve resource deletions (${context.plan.changes.remove} removals detected)"
  }
  
  check {
    condition = context.plan.changes.total <= 20
    reason    = "Test allows up to 20 changes (current: ${context.plan.changes.total})"
  }
}

# Staging: Strict guardrails with business hours enforcement
deployment_auto_approve "staging_gated" {
  check {
    condition = context.plan.applyable
    reason    = "Plan must be applyable"
  }
  
  check {
    condition = context.plan.changes.remove == 0
    reason    = "Staging cannot auto-approve resource deletions (${context.plan.changes.remove} removals detected)"
  }
  
  check {
    condition = context.plan.changes.total <= 10
    reason    = "Staging allows maximum 10 changes (current: ${context.plan.changes.total})"
  }
  
  check {
    condition = context.plan.timestamp.hour >= 9 && context.plan.timestamp.hour < 17
    reason    = "Staging deployments only auto-approve during business hours (9 AM - 5 PM UTC, current: ${context.plan.timestamp.hour}:00)"
  }
}

# Production: NO auto-approval - always requires manual review
# (No deployment_auto_approve block = manual approval required)

# ==============================================================================
# Deployment Groups
# ==============================================================================

deployment_group "development" {
  deployments = [deployment.dev]
}

deployment_group "test" {
  deployments = [deployment.test]
}

deployment_group "staging" {
  deployments = [deployment.staging]
}

deployment_group "production" {
  deployments = [deployment.production]
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
  
  # Development auto-approves with permissive rules
  deployment_group = deployment_group.development
  auto_approve_checks = [
    deployment_auto_approve.dev_rapid_iteration
  ]
  
  # flip this on only when you intend to destroy
  # destroy = true
}

deployment "test" {
  inputs = {
    regions            = ["ap-southeast-2"]  # Sydney
    role_arn           = "arn:aws:iam::258850230659:role/tfstacks-role"
    aws_identity_token = identity_token.aws.jwt
  }
  
  # Test auto-approves only if Dev is successful
  deployment_group = deployment_group.test
  auto_approve_checks = [
    deployment_auto_approve.test_safe_changes
  ]

  # flip this on only when you intend to destroy
  # destroy = true
}

deployment "staging" {
  inputs = {
    regions            = ["ap-southeast-2", "ap-southeast-1"]  # Sydney, Singapore
    role_arn           = "arn:aws:iam::258850230659:role/tfstacks-role"
    aws_identity_token = identity_token.aws.jwt
  }
  
  # Staging auto-approves only if Dev AND Test are successful + business hours
  deployment_group = deployment_group.staging
  auto_approve_checks = [
    deployment_auto_approve.staging_gated_promotion
  ]

  # flip this on only when you intend to destroy
  # destroy = true
}

deployment "production" {
  inputs = {
    regions            = ["ap-southeast-2", "ap-southeast-1"]  # Sydney, Singapore
    role_arn           = "arn:aws:iam::258850230659:role/tfstacks-role"
    aws_identity_token = identity_token.aws.jwt
  }
  
  # Production: NO auto-approval - always manual review required
  deployment_group = deployment_group.production
  # NO auto_approve_checks = manual approval enforced

  # flip this on only when you intend to destroy
  # destroy = true
}