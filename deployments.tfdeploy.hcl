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

# Development: Most permissive - auto-approve all successful plans
deployment_auto_approve "dev_rapid_iteration" {
  check {
    condition = context.plan.applyable
    reason    = "Development plan failed validation and requires manual review"
  }
  check {
    condition = context.plan.changes.total <= 50
    reason    = "Development plan exceeds 50 changes (${context.plan.changes.total} proposed) - requires manual review for safety"
  }
}

# Test: Moderate restrictions - no destroys, successful downstream dependency
deployment_auto_approve "test_safe_changes" {
  check {
    condition = context.plan.applyable
    reason    = "Test plan failed validation"
  }
  check {
    condition = context.plan.changes.remove == 0
    reason    = "Test environment does not allow resource destruction (${context.plan.changes.remove} resources would be destroyed)"
  }
  check {
    condition = context.plan.changes.total <= 20
    reason    = "Test environment limits changes to 20 (${context.plan.changes.total} changes proposed)"
  }
  check {
    # Test can only auto-approve if Dev was successful
    condition = context.plan.deployment_state("dev").status == "successful"
    reason    = "Cannot auto-approve Test until Dev deployment is successful. Current Dev status: ${context.plan.deployment_state("dev").status}"
  }
}

# Staging: Strict guardrails - requires both Dev AND Test success
deployment_auto_approve "staging_gated_promotion" {
  check {
    condition = context.plan.applyable
    reason    = "Staging plan failed validation"
  }
  check {
    condition = context.plan.changes.remove == 0
    reason    = "Staging environment prohibits resource destruction (${context.plan.changes.remove} resources would be destroyed)"
  }
  check {
    condition = context.plan.changes.total <= 10
    reason    = "Staging environment allows maximum 10 changes (${context.plan.changes.total} changes proposed)"
  }
  check {
    # Staging requires BOTH Dev AND Test to be successful (deployment pipeline)
    condition = context.plan.deployment_state("dev").status == "successful" && context.plan.deployment_state("test").status == "successful"
    reason    = "Staging requires successful Dev AND Test deployments. Dev: ${context.plan.deployment_state("dev").status}, Test: ${context.plan.deployment_state("test").status}"
  }
  check {
    # Additional business hours check for staging (enterprise requirement)
    condition = context.plan.timestamp.hour >= 9 && context.plan.timestamp.hour < 17
    reason    = "Staging deployments only auto-approve during business hours (9 AM - 5 PM UTC). Current time: ${context.plan.timestamp.hour}:00 UTC"
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