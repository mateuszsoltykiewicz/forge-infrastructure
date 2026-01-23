# ==============================================================================
# S3 Module - Local Variables
# ==============================================================================
# This file defines local variables for resource naming and tagging.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Bucket Naming (Pattern A)
  # ------------------------------------------------------------------------------

  bucket_name = "${var.common_prefix}-${var.bucket_purpose}"

  # ------------------------------------------------------------------------------
  # KMS Key Description
  # ------------------------------------------------------------------------------

  kms_key_description = "KMS encryption key for S3 bucket: ${local.bucket_name}"

  # ------------------------------------------------------------------------------
  # Resource Tagging (Pattern A)
  # ------------------------------------------------------------------------------

  # Module-specific tags
  module_tags = {
    TerraformModule = "forge/aws/storage/s3"
    Module          = "S3"
    Family          = "Storage"
    BucketPurpose   = var.bucket_purpose
    Versioning      = var.versioning_enabled ? "Enabled" : "Disabled"
    Encryption      = "aws:kms"
  }

  # Merge common_tags + module_tags
  merged_tags = merge(
    var.common_tags,
    local.module_tags
  )
}