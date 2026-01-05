# ==============================================================================
# KMS Module - Local Variables
# ==============================================================================
# This file defines local variables for resource naming and key policy.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Alias Naming
  # ------------------------------------------------------------------------------
  
  # Generate alias name based on customer context if not provided
  generated_alias_name = var.architecture_type == "shared" ? (
    # Shared: forge-{environment}-{purpose}
    "forge-${var.environment}-${var.key_purpose}"
  ) : (
    # Dedicated: {customer_name}-{purpose}
    "${var.customer_name}-${var.key_purpose}"
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
    Environment      = var.environment
    ManagedBy        = "Terraform"
    TerraformModule  = "forge/security/kms"
    Region           = var.region
    KeyPurpose       = var.key_purpose
    KeyUsage         = var.key_usage
    MultiRegion      = var.multi_region ? "true" : "false"
  }
  
  # Customer-specific tags (only for dedicated architectures)
  customer_tags = var.architecture_type != "shared" ? {
    CustomerId       = var.customer_id
    CustomerName     = var.customer_name
    ArchitectureType = var.architecture_type
    PlanTier         = var.plan_tier
  } : {}
  
  # Merge all tags
  merged_tags = merge(
    local.base_tags,
    local.customer_tags,
    var.tags
  )
}

# ------------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
