# ==============================================================================
# KMS Module - Local Variables
# ==============================================================================
# This file defines local variables for resource naming and key policy.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Alias Naming
  # ------------------------------------------------------------------------------

  # Determine naming context
  has_customer = var.customer_name != null && var.customer_name != ""
  has_project  = var.project_name != null && var.project_name != ""

  # Generate alias name based on customer context if not provided
  # 1. Shared: forge-{environment}-{purpose}
  # 2. Customer-dedicated: forge-{environment}-{customer}-{purpose}
  # 3. Project-isolated: forge-{environment}-{customer}-{project}-{purpose}
  generated_alias_name = local.has_project ? "forge-${var.environment}-${var.customer_name}-${var.project_name}-${var.key_purpose}" : (
    local.has_customer ? "forge-${var.environment}-${var.customer_name}-${var.key_purpose}" :
    "forge-${var.environment}-${var.key_purpose}"
  )

  alias_name = var.alias_name != "" ? var.alias_name : local.generated_alias_name

  # ------------------------------------------------------------------------------
  # Key Policy Construction
  # ------------------------------------------------------------------------------

  # Get current AWS account ID
  account_id = data.aws_caller_identity.current.account_id

  # Build key policy from variables (if custom policy not provided)
  default_key_policy = var.custom_key_policy == null ? jsonencode({
    Version = "2012-10-17"
    Id      = "key-policy-${local.alias_name}"
    Statement = concat(
      # Root account access (if default policy enabled)
      var.enable_default_policy ? [
        {
          Sid    = "Enable IAM User Permissions"
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::${local.account_id}:root"
          }
          Action   = "kms:*"
          Resource = "*"
        }
      ] : [],

      # Key administrators
      length(var.key_administrators) > 0 ? [
        {
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
        }
      ] : [],

      # Key users (cryptographic operations)
      length(var.key_users) > 0 ? [
        {
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
        },
        {
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
        }
      ] : [],

      # AWS Service principals
      length(var.key_service_users) > 0 ? [
        {
          Sid    = "Allow AWS services to use the key"
          Effect = "Allow"
          Principal = {
            Service = var.key_service_users
          }
          Action = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:CreateGrant",
            "kms:DescribeKey"
          ]
          Resource = "*"
          Condition = {
            StringEquals = {
              "kms:ViaService" = [
                for service in var.key_service_users :
                "${service}.${var.region}.amazonaws.com"
              ]
            }
          }
        }
      ] : []
    )
  }) : var.custom_key_policy

  # ------------------------------------------------------------------------------
  # Resource Tagging
  # ------------------------------------------------------------------------------

  # Base tags applied to all resources
  base_tags = {
    Environment     = var.environment
    ManagedBy       = "Terraform"
    TerraformModule = "forge/security/kms"
    Region          = var.region
    KeyPurpose      = var.key_purpose
    KeyUsage        = var.key_usage
    MultiRegion     = var.multi_region ? "true" : "false"
  }

  # Customer-specific tags
  customer_tags = local.has_customer ? {
    CustomerName = var.customer_name
  } : {}

  # Project-specific tags
  project_tags = local.has_project ? {
    ProjectName = var.project_name
  } : {}

  # Merge all tags
  merged_tags = merge(
    local.base_tags,
    local.customer_tags,
    local.project_tags,
    var.tags
  )
}

# ------------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
