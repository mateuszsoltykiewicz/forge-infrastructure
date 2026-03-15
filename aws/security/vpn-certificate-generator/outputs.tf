# ==============================================================================
# VPN Certificate Generator Module - Outputs
# ==============================================================================

# ------------------------------------------------------------------------------
# Certificate ARNs
# ------------------------------------------------------------------------------

output "server_cert_arn" {
  description = "ACM ARN of VPN server certificate"
  value       = local.should_generate_certs ? aws_ssm_parameter.server_arn[0].value : try(data.aws_ssm_parameter.existing_server_arn[0].value, null)
}

output "client_ca_arn" {
  description = "ACM ARN of VPN client root CA certificate"
  value       = local.should_generate_certs ? aws_ssm_parameter.client_ca_arn[0].value : try(data.aws_ssm_parameter.existing_server_arn[0].value, null) # TODO: add separate data source for client_ca
}

# ------------------------------------------------------------------------------
# Certificate Metadata
# ------------------------------------------------------------------------------

output "expiration_date" {
  description = "Certificate expiration date (ISO 8601 format)"
  value       = local.should_generate_certs ? aws_ssm_parameter.expiration_date[0].value : null
}

output "certificates_ready" {
  description = "Boolean indicating whether certificates are ready for use"
  value       = local.certificates_exist || local.should_generate_certs
}

# ------------------------------------------------------------------------------
# KMS Key
# ------------------------------------------------------------------------------

output "kms_key_arn" {
  description = "ARN of KMS key used for certificate encryption"
  value       = local.kms_key_id
}

output "kms_key_id" {
  description = "ID of KMS key used for certificate encryption"
  value       = var.kms_key_arn != null ? var.kms_key_arn : aws_kms_key.vpn_certificates[0].key_id
}

# ------------------------------------------------------------------------------
# IAM Policy
# ------------------------------------------------------------------------------

output "rotation_policy_arn" {
  description = "ARN of IAM policy for certificate rotation job (Kubernetes/Lambda)"
  value       = var.create_rotation_policy ? aws_iam_policy.rotation_access[0].arn : null
}

output "rotation_policy_name" {
  description = "Name of IAM policy for certificate rotation job"
  value       = var.create_rotation_policy ? aws_iam_policy.rotation_access[0].name : null
}

# ------------------------------------------------------------------------------
# SSM Parameter Paths
# ------------------------------------------------------------------------------

output "ssm_parameter_paths" {
  description = "Map of SSM parameter paths for all certificate components"
  value       = local.ssm_paths
}

output "ssm_base_path" {
  description = "Base SSM parameter path for VPN certificates"
  value       = local.ssm_base_path
}

# ------------------------------------------------------------------------------
# Module Information
# ------------------------------------------------------------------------------

output "certificates_generated" {
  description = "Boolean indicating whether new certificates were generated (vs using existing)"
  value       = local.should_generate_certs
}
