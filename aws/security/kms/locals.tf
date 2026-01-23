# ==============================================================================
# KMS Module - Local Variables
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Alias Naming (Pattern A)
  # ------------------------------------------------------------------------------

  # Generate alias name from common_prefix + key purpose
  generated_alias_name = "kms-${var.key_purpose}-${var.common_prefix}"

  # sanitize from generated_alias_name to be path like (lowercase, no spaces, max 63 chars)
  alias_name_sanitized_step1  = lower(replace(replace(local.generated_alias_name, "/[^a-z0-9._\\-\\/+=@ ]/", "-"), "/--+/", "-"))
  alias_name_sanitized        = substr(local.alias_name_sanitized_step1, 0, 63)
  
  # Final alias name
  alias_name                  = local.alias_name_sanitized

  # ------------------------------------------------------------------------------
  # Tagging Strategy (Pattern A)
  # ------------------------------------------------------------------------------

  # Module-specific tags (only KMS metadata)
  module_tags = {
    TerraformModule = "forge/aws/security/kms"
    KeyPurpose      = var.key_purpose
    KeyUsage        = var.key_usage
    MultiRegion     = tostring(var.multi_region)
    KeySpec         = var.customer_master_key_spec
  }

  # Merge common_tags from root + module-specific tags
  merged_tags = merge(
    var.common_tags,
    local.module_tags
  )

  # ------------------------------------------------------------------------------
  # Key Policy Construction
  # ------------------------------------------------------------------------------

  # Get current AWS account ID
  account_id = data.aws_caller_identity.current.account_id

  # ------------------------------------------------------------------------------
  # Policy Statements (separated for type consistency)
  # ------------------------------------------------------------------------------

  root_policy_statements = var.enable_default_policy ? [{
    Sid    = "Enable IAM User Permissions"
    Effect = "Allow"
    Principal = {
      AWS = "arn:aws:iam::${local.account_id}:root"
    }
    Action   = "kms:*"
    Resource = "*"
  }] : []

  admin_policy_statements = length(var.key_administrators) > 0 ? [{
    Sid    = "Allow access for Key Administrators"
    Effect = "Allow"
    Principal = {
      AWS = var.key_administrators
    }
    Action = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    Resource = "*"
  }] : []

  # User statements split into two separate locals
  user_use_statements = length(var.key_users) > 0 ? [{
    Sid    = "Allow use of the key"
    Effect = "Allow"
    Principal = {
      AWS = var.key_users
    }
    Action = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    Resource = "*"
  }] : []

  user_grant_statements = length(var.key_users) > 0 ? [{
    Sid    = "Allow attachment of persistent resources"
    Effect = "Allow"
    Principal = {
      AWS = var.key_users
    }
    Action = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    Resource = "*"
    Condition = {
      Bool = {
        "kms:GrantIsForAWSResource" = "true"
      }
    }
  }] : []

  service_policy_statements = length(var.key_service_roles) > 0 ? [{
    Sid    = "Allow AWS Services to use the key"
    Effect = "Allow"
    Principal = {
      Service = var.key_service_roles
    }
    Action = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    Resource = "*"
  }] : []

  # Build key policy from variables (if custom policy not provided)
  default_key_policy = var.custom_key_policy == null ? jsonencode({
    Version = "2012-10-17"
    Id      = "key-policy-${local.alias_name}"
    Statement = concat(
      local.root_policy_statements,
      local.admin_policy_statements,
      local.user_use_statements,
      local.user_grant_statements,
      local.service_policy_statements
    )
  }) : var.custom_key_policy

  # Final key policy
  key_policy = local.default_key_policy
}