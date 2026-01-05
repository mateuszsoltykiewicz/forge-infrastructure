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
  value       = aws_ssm_parameter.this.name
}

output "parameter_arn" {
  description = "ARN of the parameter"
  value       = aws_ssm_parameter.this.arn
}

output "parameter_version" {
  description = "Version of the parameter"
  value       = aws_ssm_parameter.this.version
}

# ------------------------------------------------------------------------------
# Parameter Configuration
# ------------------------------------------------------------------------------

output "parameter_type" {
  description = "Type of the parameter"
  value       = aws_ssm_parameter.this.type
}

output "parameter_tier" {
  description = "Tier of the parameter"
  value       = aws_ssm_parameter.this.tier
}

output "parameter_data_type" {
  description = "Data type of the parameter"
  value       = aws_ssm_parameter.this.data_type
}

# ------------------------------------------------------------------------------
# Parameter Value (Sensitive)
# ------------------------------------------------------------------------------

output "parameter_value" {
  description = "Value of the parameter (sensitive)"
  value       = aws_ssm_parameter.this.value
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Encryption
# ------------------------------------------------------------------------------

output "kms_key_id" {
  description = "KMS key ID used for SecureString encryption"
  value       = aws_ssm_parameter.this.key_id
}

# ------------------------------------------------------------------------------
# Metadata
# ------------------------------------------------------------------------------

output "parameter_insecure_value" {
  description = "Insecure value of the parameter (only for non-SecureString types)"
  value       = var.parameter_type != "SecureString" ? aws_ssm_parameter.this.insecure_value : null
}
