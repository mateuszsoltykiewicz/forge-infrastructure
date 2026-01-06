# ==============================================================================
# SSM Parameter Module - Outputs
# ==============================================================================
# This file defines outputs for the SSM parameter.
# ==============================================================================

# ------------------------------------------------------------------------------
# Parameter Identification
# ------------------------------------------------------------------------------

output "parameter_name" {
  description = "Full name (path) of the parameter"
  value       = var.create ? aws_ssm_parameter.this[0].name : null
}

output "parameter_arn" {
  description = "ARN of the parameter"
  value       = var.create ? aws_ssm_parameter.this[0].arn : null
}

output "parameter_version" {
  description = "Version of the parameter"
  value       = var.create ? aws_ssm_parameter.this[0].version : null
}

# ------------------------------------------------------------------------------
# Parameter Configuration
# ------------------------------------------------------------------------------

output "parameter_type" {
  description = "Type of the parameter"
  value       = var.create ? aws_ssm_parameter.this[0].type : null
}

output "parameter_tier" {
  description = "Tier of the parameter"
  value       = var.create ? aws_ssm_parameter.this[0].tier : null
}

output "parameter_data_type" {
  description = "Data type of the parameter"
  value       = var.create ? aws_ssm_parameter.this[0].data_type : null
}

# ------------------------------------------------------------------------------
# Parameter Value (Sensitive)
# ------------------------------------------------------------------------------

output "parameter_value" {
  description = "Value of the parameter (sensitive)"
  value       = var.create ? aws_ssm_parameter.this[0].value : null
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Encryption
# ------------------------------------------------------------------------------

output "kms_key_id" {
  description = "KMS key ID used for SecureString encryption"
  value       = var.create ? aws_ssm_parameter.this[0].key_id : null
}

# ------------------------------------------------------------------------------
# Metadata
# ------------------------------------------------------------------------------

output "parameter_insecure_value" {
  description = "Insecure value of the parameter (only for non-SecureString types)"
  value       = var.create && var.parameter_type != "SecureString" ? aws_ssm_parameter.this[0].insecure_value : null
}
