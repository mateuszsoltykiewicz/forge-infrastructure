# ==============================================================================
# KMS Key for VPC Flow Logs Encryption
# ==============================================================================
# Encrypts VPC Flow Logs in CloudWatch Logs for security and compliance.
# Uses centralized KMS module with service principal permissions.
# ==============================================================================

module "kms_flow_logs" {
  source = "../../security/kms"

  # Pattern A variables
  common_prefix = var.common_prefix
  common_tags   = var.common_tags

  # Environment context
  environment = "shared" # VPC is shared across environments
  region      = var.aws_region

  # KMS Key configuration
  key_purpose     = "vpc-flow-logs"
  key_description = "VPC Flow Logs ${local.vpc_name} encryption (CloudWatch Logs)"
  key_usage       = "ENCRYPT_DECRYPT"

  # Security settings
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = var.enable_kms_key_rotation

  # Service principals - CloudWatch Logs and VPC Flow Logs
  key_service_roles = [
    "logs.${var.aws_region}.amazonaws.com",
    "vpc-flow-logs.amazonaws.com"
  ]

  # Root account as administrator
  key_administrators = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
}
