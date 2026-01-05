# ==============================================================================
# S3 Module - Local Variables
# ==============================================================================
# This file defines local variables for resource naming and tagging.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Bucket Naming
  # ------------------------------------------------------------------------------
  
  # Generate bucket name based on customer context if not provided
  generated_bucket_name = var.architecture_type == "shared" ? (
    # Shared: forge-{environment}-{purpose}-{region}
    "forge-${var.environment}-${var.bucket_purpose}-${var.region}"
  ) : (
    # Dedicated: {customer_name}-{region}-{purpose}
    "${var.customer_name}-${var.region}-${var.bucket_purpose}"
  )
  
  bucket_name = var.bucket_name != "" ? var.bucket_name : local.generated_bucket_name

  # ------------------------------------------------------------------------------
  # Resource Tagging
  # ------------------------------------------------------------------------------
  
  # Base tags applied to all resources
  base_tags = {
    Environment      = var.environment
    ManagedBy        = "Terraform"
    TerraformModule  = "forge/storage/s3"
    Region           = var.region
    BucketPurpose    = var.bucket_purpose
    Versioning       = var.versioning_enabled ? "Enabled" : "Disabled"
    Encryption       = var.encryption_enabled ? var.encryption_type : "None"
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
