# ==============================================================================
# IAM Role Module - Local Variables
# ==============================================================================
# This file defines local variables for resource naming and tagging.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Role Naming
  # ------------------------------------------------------------------------------
  
  # Generate role name based on customer context if not provided
  generated_role_name = var.architecture_type == "shared" ? (
    # Shared: forge-{environment}-{purpose}
    "forge-${var.environment}-${var.role_purpose}"
  ) : (
    # Dedicated: {customer_name}-{purpose}
    "${var.customer_name}-${var.role_purpose}"
  )
  
  role_name = var.role_name != "" ? var.role_name : local.generated_role_name

  # ------------------------------------------------------------------------------
  # Trust Policy Construction
  # ------------------------------------------------------------------------------
  
  # Build trust policy from variables (if custom policy not provided)
  default_assume_role_policy = var.custom_assume_role_policy == null ? jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # AWS Service principals
      length(var.trusted_services) > 0 ? [
        {
          Effect = "Allow"
          Principal = {
            Service = var.trusted_services
          }
          Action = "sts:AssumeRole"
        }
      ] : [],
      
      # AWS Account principals
      length(var.trusted_aws_accounts) > 0 ? [
        {
          Effect = "Allow"
          Principal = {
            AWS = [for account in var.trusted_aws_accounts : "arn:aws:iam::${account}:root"]
          }
          Action = "sts:AssumeRole"
        }
      ] : [],
      
      # Federated principals (OIDC/SAML)
      length(var.trusted_federated_arns) > 0 ? [
        {
          Effect = "Allow"
          Principal = {
            Federated = var.trusted_federated_arns
          }
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = var.oidc_condition != null ? {
            (var.oidc_condition.test) = {
              (var.oidc_condition.variable) = var.oidc_condition.values
            }
          } : null
        }
      ] : []
    )
  }) : var.custom_assume_role_policy

  # ------------------------------------------------------------------------------
  # Resource Tagging
  # ------------------------------------------------------------------------------
  
  # Base tags applied to all resources
  base_tags = {
    Environment      = var.environment
    ManagedBy        = "Terraform"
    TerraformModule  = "forge/iam/iam-role"
    Region           = var.region
    RolePurpose      = var.role_purpose
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
