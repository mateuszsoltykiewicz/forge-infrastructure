# ==============================================================================
# VPC Module Outputs (Forge - Customer-Centric)
# ==============================================================================

# ------------------------------------------------------------------------------
# VPC Identifiers
# ------------------------------------------------------------------------------

output "vpc_id" {
  value       = aws_vpc.this.id
  description = "The ID of the created VPC."
}

output "vpc_arn" {
  value       = aws_vpc.this.arn
  description = "The Amazon Resource Name (ARN) of the created VPC."
}

output "vpc_name" {
  value       = local.vpc_name
  description = "The name of the VPC."
}

output "cidr_block" {
  value       = var.cidr_block
  description = "The primary CIDR block of the VPC."
}

# ------------------------------------------------------------------------------
# VPC Flow Logs
# ------------------------------------------------------------------------------

output "flow_log_id" {
  value       = aws_flow_log.main.id
  description = "The ID of the VPC Flow Log (null if flow logs disabled)."
}

output "flow_log_arn" {
  value       = aws_flow_log.main.arn
  description = "The ARN of the VPC Flow Log (null if flow logs disabled)."
}

output "flow_logs_log_group_name" {
  value       = aws_cloudwatch_log_group.flow_logs.name
  description = "The CloudWatch Log Group name for flow logs (null if disabled)."
}

output "flow_logs_iam_role_arn" {
  value       = aws_iam_role.flow_logs.arn
  description = "The IAM role ARN used by VPC Flow Logs (null if disabled)."
}

# ------------------------------------------------------------------------------
# KMS Key for Flow Logs Encryption
# ------------------------------------------------------------------------------

output "flow_logs_kms_key_id" {
  value       = module.kms_flow_logs.key_id
  description = "The KMS key ID used for flow logs encryption."
}

output "flow_logs_kms_key_arn" {
  value       = module.kms_flow_logs.key_arn
  description = "The KMS key ARN used for flow logs encryption."
}

output "flow_logs_kms_alias_name" {
  value       = module.kms_flow_logs.alias_name
  description = "The KMS key alias name for flow logs encryption."
}
