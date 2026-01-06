# ==============================================================================
# KMS Module - Outputs
# ==============================================================================
# This file exports essential information about the created KMS key.
# ==============================================================================

# ------------------------------------------------------------------------------
# KMS Key Outputs
# ------------------------------------------------------------------------------

output "key_id" {
  description = "The globally unique identifier for the key"
  value       = var.create ? aws_kms_key.main[0].key_id : null
}

output "key_arn" {
  description = "The ARN of the key"
  value       = var.create ? aws_kms_key.main[0].arn : null
}

output "key_multi_region" {
  description = "Whether the key is a multi-region key"
  value       = var.create ? aws_kms_key.main[0].multi_region : null
}

output "key_rotation_enabled" {
  description = "Whether automatic key rotation is enabled"
  value       = var.create ? aws_kms_key.main[0].enable_key_rotation : null
}

output "key_rotation_period_in_days" {
  description = "The rotation period in days"
  value       = var.create ? aws_kms_key.main[0].rotation_period_in_days : null
}

# ------------------------------------------------------------------------------
# KMS Alias Outputs
# ------------------------------------------------------------------------------

output "alias_name" {
  description = "The display name of the alias"
  value       = var.create && var.create_alias ? aws_kms_alias.main[0].name : null
}

output "alias_arn" {
  description = "The ARN of the alias"
  value       = var.create && var.create_alias ? aws_kms_alias.main[0].arn : null
}

output "alias_target_key_arn" {
  description = "The ARN of the target key"
  value       = var.create && var.create_alias ? aws_kms_alias.main[0].target_key_arn : null
}

# ------------------------------------------------------------------------------
# Grant Outputs
# ------------------------------------------------------------------------------

output "grant_ids" {
  description = "Map of grant names to grant IDs"
  value       = var.create ? { for k, v in aws_kms_grant.main : k => v.grant_id } : {}
}

output "grant_tokens" {
  description = "Map of grant names to grant tokens"
  value       = var.create ? { for k, v in aws_kms_grant.main : k => v.grant_token } : {}
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Metadata Outputs
# ------------------------------------------------------------------------------

output "key_purpose" {
  description = "The purpose of this key"
  value       = var.key_purpose
}

output "key_usage" {
  description = "The intended use of the key"
  value       = var.key_usage
}

output "tags" {
  description = "All tags applied to the key"
  value       = var.create ? aws_kms_key.main[0].tags_all : {}
}
