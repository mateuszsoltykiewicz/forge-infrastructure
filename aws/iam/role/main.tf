# ==============================================================================
# IAM Role Module - Main Resources
# ==============================================================================
# This file creates IAM role resources with trust policies, managed policies,
# and inline policies.
# ==============================================================================

# ------------------------------------------------------------------------------
# IAM Role
# ------------------------------------------------------------------------------

resource "aws_iam_role" "main" {
  name                 = local.role_name
  description          = var.role_description
  assume_role_policy   = local.default_assume_role_policy
  max_session_duration = var.max_session_duration
  force_detach_policies = var.force_detach_policies
  permissions_boundary  = var.permissions_boundary_arn

  tags = merge(
    local.merged_tags,
    {
      Name = local.role_name
    }
  )
}

# ------------------------------------------------------------------------------
# AWS Managed Policy Attachments
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "aws_managed" {
  for_each = toset(var.aws_managed_policy_arns)

  role       = aws_iam_role.main.name
  policy_arn = each.value
}

# ------------------------------------------------------------------------------
# Customer Managed Policy Attachments
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "customer_managed" {
  for_each = toset(var.customer_managed_policy_arns)

  role       = aws_iam_role.main.name
  policy_arn = each.value
}

# ------------------------------------------------------------------------------
# Inline Policies
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.main.id
  policy = each.value
}

# ------------------------------------------------------------------------------
# Instance Profile (for EC2/EKS nodes)
# ------------------------------------------------------------------------------

resource "aws_iam_instance_profile" "main" {
  count = var.create_instance_profile ? 1 : 0

  name = local.role_name
  role = aws_iam_role.main.name

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.role_name}-instance-profile"
    }
  )
}
