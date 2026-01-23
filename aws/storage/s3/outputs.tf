# ==============================================================================
# S3 Module - Outputs
# ==============================================================================
# This file exports essential information about the created S3 bucket.
# ==============================================================================

# ------------------------------------------------------------------------------
# Bucket Identification Outputs
# ------------------------------------------------------------------------------

output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name (bucket-name.s3.amazonaws.com)"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name (bucket-name.s3.region.amazonaws.com)"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = aws_s3_bucket.main.region
}

output "bucket_hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for this bucket's region"
  value       = aws_s3_bucket.main.hosted_zone_id
}

# ------------------------------------------------------------------------------
# Configuration Outputs
# ------------------------------------------------------------------------------

output "versioning_enabled" {
  description = "Whether versioning is enabled for this bucket"
  value       = var.versioning_enabled
}

output "encryption_type" {
  description = "The type of encryption used (always aws:kms)"
  value       = "aws:kms"
}

output "kms_key_id" {
  description = "The KMS key ID used for bucket encryption"
  value       = module.kms_s3.key_id
}

output "kms_key_arn" {
  description = "The KMS key ARN used for bucket encryption"
  value       = module.kms_s3.key_arn
}

output "kms_alias_name" {
  description = "The KMS key alias name"
  value       = module.kms_s3.alias_name
}

output "public_access_blocked" {
  description = "Whether all public access is blocked for this bucket"
  value       = var.block_public_access
}

output "replication_enabled" {
  description = "Whether cross-region replication is enabled"
  value       = var.replication_enabled
}

output "object_lock_enabled" {
  description = "Whether Object Lock (WORM) is enabled"
  value       = var.object_lock_enabled
}

# ------------------------------------------------------------------------------
# Metadata Outputs
# ------------------------------------------------------------------------------

output "tags" {
  description = "All tags applied to the bucket"
  value       = aws_s3_bucket.main.tags_all
}

output "bucket_purpose" {
  description = "The purpose of this bucket"
  value       = var.bucket_purpose
}