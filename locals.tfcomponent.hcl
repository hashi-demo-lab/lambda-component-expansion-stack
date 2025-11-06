# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# ==============================================================================
# Naming Conventions
# ==============================================================================

locals {
  # Standardized naming prefix for all resources
  name_prefix = "serverless-api-${var.environment}"
  
  # Common resource naming pattern
  resource_name_pattern = "${local.name_prefix}-%s"
  
  # Stack identifier for cross-stack references
  stack_id = "serverless-api-stack"
}

# ==============================================================================
# Environment-Specific Configuration
# ==============================================================================

locals {
  # Environment tier classification
  environment_tier = {
    dev        = "non-production"
    test       = "non-production"
    staging    = "pre-production"
    production = "production"
  }
  
  # Is this a production environment?
  is_production = var.environment == "production"
  
  # Environment-specific defaults
  environment_defaults = {
    dev = {
      min_capacity = 1
      max_capacity = 5
      alarm_enabled = false
    }
    test = {
      min_capacity = 1
      max_capacity = 10
      alarm_enabled = true
    }
    staging = {
      min_capacity = 2
      max_capacity = 20
      alarm_enabled = true
    }
    production = {
      min_capacity = 3
      max_capacity = 50
      alarm_enabled = true
    }
  }
}

# ==============================================================================
# Computed Tags
# ==============================================================================

locals {
  # Merge default tags with computed tags
  computed_tags = merge(
    var.default_tags,
    {
      StackName       = local.stack_id
      Environment     = var.environment
      EnvironmentTier = local.environment_tier[var.environment]
      ManagedBy       = "Terraform-Stacks"
      DeployedAt      = timestamp()
    }
  )
  
  # Compliance tags for production
  compliance_tags = local.is_production ? {
    Compliance      = "Required"
    DataClass       = "Confidential"
    BackupRequired  = "true"
    DisasterRecovery = "Required"
  } : {}
  
  # Final merged tags
  final_tags = merge(local.computed_tags, local.compliance_tags)
}

# ==============================================================================
# Regional Configuration
# ==============================================================================

locals {
  # Map regions to their friendly names
  region_names = {
    "us-east-1"    = "us-virginia"
    "us-east-2"    = "us-ohio"
    "us-west-1"    = "us-california"
    "us-west-2"    = "us-oregon"
    "eu-west-1"    = "eu-ireland"
    "eu-west-2"    = "eu-london"
    "eu-central-1" = "eu-frankfurt"
    "ap-south-1"   = "ap-mumbai"
    "ap-southeast-1" = "ap-singapore"
    "ap-southeast-2" = "ap-sydney"
    "ap-northeast-1" = "ap-tokyo"
  }
  
  # Multi-region deployment indicator
  is_multi_region = length(var.regions) > 1
  
  # Primary region (first in the list)
  primary_region = sort(tolist(var.regions))[0]
}

# ==============================================================================
# Cost Allocation
# ==============================================================================

locals {
  # Cost center mapping by environment
  cost_center = {
    dev        = "Engineering-Development"
    test       = "Engineering-QA"
    staging    = "Engineering-PreProd"
    production = "Production-Services"
  }
  
  # Estimated monthly cost tier
  cost_tier = local.is_production ? "high" : "low"
}

# ==============================================================================
# Monitoring & Observability
# ==============================================================================

locals {
  # Log retention periods based on environment
  default_log_retention = {
    dev        = 7
    test       = 14
    staging    = 30
    production = 90
  }
  
  # Effective log retention (use deployment input or default)
  log_retention = coalesce(
    var.log_retention_days,
    local.default_log_retention[var.environment]
  )
  
  # Enable detailed CloudWatch metrics for production
  enable_detailed_metrics = local.is_production
  
  # Alarm configuration
  alarm_config = local.environment_defaults[var.environment]
}
