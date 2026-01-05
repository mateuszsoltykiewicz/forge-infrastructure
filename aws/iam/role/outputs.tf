# ==============================================================================
# IAM Role Module - Outputs
# ==============================================================================
# This file exports essential information about the created IAM role.
# ==============================================================================

# ------------------------------------------------------------------------------
# Role Outputs
# ------------------------------------------------------------------------------

output "role_name" {
  description = "The name of the IAM role"
  value       = aws_iam_role.main.name
}

output "role_arn" {
  description = "The ARN of the IAM role"
  value       = aws_iam_role.main.arn
}

output "role_id" {
  description = "The unique ID of the IAM role"
  value       = aws_iam_role.main.unique_id
}

output "role_path" {
  description = "The path of the IAM role"
  value       = aws_iam_role.main.path
}

# ------------------------------------------------------------------------------
# Instance Profile Outputs
# ------------------------------------------------------------------------------

output "instance_profile_name" {
  description = "The name of the instance profile (if created)"
  value       = var.create_instance_profile ? aws_iam_instance_profile.main[0].name : null
}

output "instance_profile_arn" {
  description = "The ARN of the instance profile (if created)"
  value       = var.create_instance_profile ? aws_iam_instance_profile.main[0].arn : null
}

output "instance_profile_id" {
  description = "The unique ID of the instance profile (if created)"
  value       = var.create_instance_profile ? aws_iam_instance_profile.main[0].unique_id : null
}

# ------------------------------------------------------------------------------
# Policy Attachments Outputs
# ------------------------------------------------------------------------------

output "aws_managed_policy_arns" {
  description = "List of attached AWS managed policy ARNs"
  value       = var.aws_managed_policy_arns
}

output "customer_managed_policy_arns" {
  description = "List of attached customer managed policy ARNs"
  value       = var.customer_managed_policy_arns
}

output "inline_policy_names" {
  description = "List of inline policy names"
  value       = keys(var.inline_policies)
}

# ------------------------------------------------------------------------------
# Metadata Outputs
# ------------------------------------------------------------------------------

output "role_purpose" {
  description = "The purpose of this role"
  value       = var.role_purpose
}

output "tags" {
  description = "All tags applied to the role"
  value       = aws_iam_role.main.tags_all
}
