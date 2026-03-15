# ==============================================================================
# S3 HIPAA Logs Module - Outputs
# ==============================================================================
# Exposes bucket ARNs, KMS keys, and replication role for integration
# ==============================================================================

# ------------------------------------------------------------------------------
# Primary Bucket Outputs
# ------------------------------------------------------------------------------

output "primary_bucket_id" {
  description = "Primary HIPAA logs S3 bucket ID"
  value       = aws_s3_bucket.primary.id
}

output "primary_bucket_arn" {
  description = "Primary HIPAA logs S3 bucket ARN (for Kinesis Firehose)"
  value       = aws_s3_bucket.primary.arn
}

output "primary_kms_key_arn" {
  description = "Primary region KMS key ARN for S3 encryption"
  value       = module.kms_s3_primary.key_arn
}

output "primary_kms_key_id" {
  description = "Primary region KMS key ID for S3 encryption"
  value       = module.kms_s3_primary.key_id
}

# ------------------------------------------------------------------------------
# DR Bucket Outputs
# ------------------------------------------------------------------------------

output "dr_bucket_arn" {
  description = "DR HIPAA logs S3 bucket ARN (replication destination)"
  value       = aws_s3_bucket.dr.arn
}

output "dr_kms_key_arn" {
  description = "DR region KMS key ARN for S3 encryption"
  value       = module.kms_s3_dr.key_arn
}

# ------------------------------------------------------------------------------
# Replication Outputs
# ------------------------------------------------------------------------------

output "replication_role_arn" {
  description = "IAM role ARN for S3 cross-region replication"
  value       = aws_iam_role.replication.arn
}
