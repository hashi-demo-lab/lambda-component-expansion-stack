# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "bucket_id" {
  description = "The ID of the S3 bucket to be used by a downstream component in this stack."
  value       = aws_s3_bucket.lambda_bucket.id
}

output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.lambda_bucket.bucket
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.lambda_bucket.arn
}
