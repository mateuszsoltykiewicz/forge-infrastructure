# ==============================================================================
# S3 Module - Local Variables
# ==============================================================================
# This file defines local variables for resource naming and tagging.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Bucket Naming
  # ------------------------------------------------------------------------------

  # Determine naming context
  has_customer = var.customer_name != null && var.customer_name != ""
  has_project  = var.project_name != null && var.project_name != ""

  # Generate bucket name based on customer context if not provided
  # 1. Shared: forge-{environment}-{purpose}
  # 2. Customer-dedicated: forge-{environment}-{customer}-{purpose}
  # 3. Project-isolated: forge-{environment}-{customer}-{project}-{purpose}
  generated_bucket_name = local.has_project ? "forge-${var.environment}-${var.customer_name}-${var.project_name}-${var.bucket_purpose}" : (
    local.has_customer ? "forge-${var.environment}-${var.customer_name}-${var.bucket_purpose}" :
    "forge-${var.environment}-${var.bucket_purpose}"
  )

  bucket_name = var.bucket_name != "" ? var.bucket_name : local.generated_bucket_name

  # ------------------------------------------------------------------------------
  # Resource Tagging
  # ------------------------------------------------------------------------------

  # Base tags applied to all resources
  base_tags = {
    Environment     = var.environment
    ManagedBy       = "Terraform"
    TerraformModule = "forge/storage/s3"
    Region          = var.region
    BucketPurpose   = var.bucket_purpose
    Versioning      = var.versioning_enabled ? "Enabled" : "Disabled"
    Encryption      = var.encryption_enabled ? var.encryption_type : "None"
  }

  # Customer-specific tags
  customer_tags = local.has_customer ? {
    Customer = var.customer_name
  } : {}

  project_tags = local.has_project ? {
    Project = var.project_name
  } : {}

  # Merge all tags
  merged_tags = merge(
    local.base_tags,
    local.customer_tags,
    local.project_tags,
    var.tags
  )
}
