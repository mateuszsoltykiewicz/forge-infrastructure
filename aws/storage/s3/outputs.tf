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
  value       = var.create ? aws_s3_bucket.main[0].id : null
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = var.create ? aws_s3_bucket.main[0].arn : null
}

output "bucket_domain_name" {
  description = "The bucket domain name (bucket-name.s3.amazonaws.com)"
  value       = var.create ? aws_s3_bucket.main[0].bucket_domain_name : null
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name (bucket-name.s3.region.amazonaws.com)"
  value       = var.create ? aws_s3_bucket.main[0].bucket_regional_domain_name : null
}

output "bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = var.create ? aws_s3_bucket.main[0].region : null
}

output "bucket_hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for this bucket's region"
  value       = var.create ? aws_s3_bucket.main[0].hosted_zone_id : null
}

# ------------------------------------------------------------------------------
# Configuration Outputs
# ------------------------------------------------------------------------------

output "versioning_enabled" {
  description = "Whether versioning is enabled for this bucket"
  value       = var.versioning_enabled
}

output "encryption_enabled" {
  description = "Whether server-side encryption is enabled"
  value       = var.encryption_enabled
}

output "encryption_type" {
  description = "The type of encryption used (AES256 or aws:kms)"
  value       = var.encryption_enabled ? var.encryption_type : null
}

output "kms_key_id" {
  description = "The KMS key ID used for encryption (if applicable)"
  value       = var.encryption_enabled && var.encryption_type == "aws:kms" ? var.kms_key_id : null
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
# Access Information Outputs
# ------------------------------------------------------------------------------

output "bucket_website_endpoint" {
  description = "The website endpoint (if bucket is configured for static hosting)"
  value       = try(var.create ? aws_s3_bucket.main[0].website_endpoint : null, "")
}

output "bucket_website_domain" {
  description = "The domain of the website endpoint (if bucket is configured for static hosting)"
  value       = try(var.create ? aws_s3_bucket.main[0].website_domain : null, "")
}

# ------------------------------------------------------------------------------
# Metadata Outputs
# ------------------------------------------------------------------------------

output "tags" {
  description = "All tags applied to the bucket"
  value       = var.create ? aws_s3_bucket.main[0].tags_all : null
}

output "bucket_purpose" {
  description = "The purpose of this bucket"
  value       = var.bucket_purpose
}
