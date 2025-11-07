# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# ==============================================================================
# Regional Configuration
# ==============================================================================

locals {
  # Map regions to their friendly names
  region_names = {
    "us-east-1"      = "us-virginia"
    "us-east-2"      = "us-ohio"
    "us-west-1"      = "us-california"
    "us-west-2"      = "us-oregon"
    "eu-west-1"      = "eu-ireland"
    "eu-west-2"      = "eu-london"
    "eu-central-1"   = "eu-frankfurt"
    "ap-south-1"     = "ap-mumbai"
    "ap-southeast-1" = "ap-singapore"
    "ap-southeast-2" = "ap-sydney"
    "ap-southeast-4" = "ap-melbourne"
    "ap-northeast-1" = "ap-tokyo"
  }
  
  # Multi-region deployment indicator
  is_multi_region = length(var.regions) > 1
  
  # Primary region (first in the list)
  primary_region = sort(tolist(var.regions))[0]
}
