# ==============================================================================
# S3 HIPAA Logs Module - Local Values
# ==============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  # ------------------------------------------------------------------------------
  # Bucket Naming (globally unique, kebab-case)
  # ------------------------------------------------------------------------------

  bucket_name_primary = "${var.common_prefix}-hipaa-logs-${var.primary_region}"
  bucket_name_dr      = "${var.common_prefix}-hipaa-logs-${var.dr_region}"

  # ------------------------------------------------------------------------------
  # IAM Naming (PascalCase for IAM roles per AWS convention)
  # ------------------------------------------------------------------------------

  # Convert common_prefix to PascalCase for IAM role
  pascal_prefix         = join("", [for part in split("-", var.common_prefix) : title(part)])
  replication_role_name = "${local.pascal_prefix}S3ReplicationHipaaLogs"

  # ------------------------------------------------------------------------------
  # Tags
  # ------------------------------------------------------------------------------

  merged_tags = merge(
    var.common_tags,
    {
      TerraformModule = "forge/aws/logging/hipaa"
      Module          = "S3 HIPAA Logs"
      Purpose         = "HIPAA Logs Storage with Cross-Region Replication"
    }
  )
}
