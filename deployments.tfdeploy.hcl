# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

identity_token "aws" {
  audience = ["terraform-stacks-private-preview"]
}

deployment "development" {
  inputs = {
    regions        = ["ap-southeast-2"]
    role_arn       = "arn:aws:iam::855831148133:role/tfstacks-role"
    identity_token = identity_token.aws.jwt
    default_tags   = { stacks-preview-example = "lambda-component-expansion-stack" }
  }
}

# deployment "production" {
#   inputs = {
#     regions        = ["ap-southeast-2", "ap-southeast-1"]
#     role_arn       = "arn:aws:iam::855831148133:role/tfstacks-role"
#     identity_token = identity_token.aws.jwt
#     default_tags   = { stacks-preview-example = "lambda-component-expansion-stack" }
#   }
# }

