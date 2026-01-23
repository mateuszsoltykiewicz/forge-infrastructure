# ==============================================================================
# SSM Parameter Module - Main Resources
# ==============================================================================
# This file defines the SSM Parameter Store parameter resource.
# ==============================================================================

# ------------------------------------------------------------------------------
# SSM Parameter
# ------------------------------------------------------------------------------

resource "aws_ssm_parameter" "this" {

  name        = local.parameter_full_path
  description = var.description
  type        = var.parameter_type
  value       = var.parameter_value
  tier        = var.parameter_tier

  # KMS encryption (required for SecureString)
  key_id = var.parameter_type == "SecureString" ? var.kms_key_id : null

  # Data type
  data_type = var.data_type

  # Allowed pattern validation
  allowed_pattern = var.allowed_pattern

  # Overwrite behavior
  overwrite = var.overwrite

  tags = local.merged_tags # <-- Pattern A tagging

  lifecycle {
    # Prevent accidental deletion of critical parameters
    prevent_destroy = var.prevent_destroy

    # Ignore changes to value if managed externally
    ignore_changes = var.ignore_value_changes ? [value] : []

    # Validation: SecureString requires KMS key
    precondition {
      condition     = local.kms_validation_passed
      error_message = "SecureString parameter type requires kms_key_id to be specified"
    }
  }
}
