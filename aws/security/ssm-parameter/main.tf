# ==============================================================================
# SSM Parameter Module - Main Resources
# ==============================================================================
# This file defines the SSM Parameter Store parameter resource.
# ==============================================================================

# ------------------------------------------------------------------------------
# SSM Parameter
# ------------------------------------------------------------------------------

resource "aws_ssm_parameter" "this" {
  name            = local.parameter_full_path
  description     = var.parameter_description != "" ? var.parameter_description : "Parameter ${local.parameter_display_name} for ${var.resource_type}"
  type            = var.parameter_type
  tier            = var.parameter_tier
  value           = var.parameter_value
  key_id          = var.parameter_type == "SecureString" ? var.kms_key_id : null
  data_type       = var.data_type
  allowed_pattern = var.allowed_pattern
  overwrite       = var.overwrite

  tags = local.merged_tags

  lifecycle {
    # Prevent accidental deletion of parameters
    prevent_destroy = false

    # Ignore changes to value if managed externally
    ignore_changes = []
  }
}
