# ==============================================================================
# KMS Module - Main Resources
# ==============================================================================
# This file creates KMS key resources with key policy, alias, and grants.
# ==============================================================================

# ------------------------------------------------------------------------------
# KMS Key
# ------------------------------------------------------------------------------

resource "aws_kms_key" "main" {
  count = var.create ? 1 : 0

  description              = var.key_description
  key_usage                = var.key_usage
  customer_master_key_spec = var.customer_master_key_spec
  multi_region             = var.multi_region

  # Automatic key rotation (only for symmetric keys)
  enable_key_rotation = (
    var.customer_master_key_spec == "SYMMETRIC_DEFAULT" &&
    var.enable_key_rotation
  )

  rotation_period_in_days = (
    var.customer_master_key_spec == "SYMMETRIC_DEFAULT" &&
    var.enable_key_rotation ?
    var.rotation_period_in_days :
    null
  )

  deletion_window_in_days            = var.deletion_window_in_days
  is_enabled                         = var.is_enabled
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check

  policy = local.default_key_policy

  tags = merge(
    local.merged_tags,
    {
      Name = local.alias_name
    }
  )
}

# ------------------------------------------------------------------------------
# KMS Alias
# ------------------------------------------------------------------------------

resource "aws_kms_alias" "main" {
  count = var.create && var.create_alias ? 1 : 0

  name          = "alias/${local.alias_name}"
  target_key_id = aws_kms_key.main[0].key_id
}

# ------------------------------------------------------------------------------
# KMS Grants
# ------------------------------------------------------------------------------

resource "aws_kms_grant" "main" {
  for_each = var.create ? { for grant in var.grants : grant.name => grant } : {}

  name              = each.value.name
  key_id            = aws_kms_key.main[0].key_id
  grantee_principal = each.value.grantee_principal
  operations        = each.value.operations

  dynamic "constraints" {
    for_each = each.value.constraints != null ? [each.value.constraints] : []

    content {
      encryption_context_equals = constraints.value.encryption_context_equals
      encryption_context_subset = constraints.value.encryption_context_subset
    }
  }

  retiring_principal    = each.value.retiring_principal
  grant_creation_tokens = each.value.grant_creation_tokens
}
