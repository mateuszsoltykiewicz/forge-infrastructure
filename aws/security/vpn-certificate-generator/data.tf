# ==============================================================================
# VPN Certificate Generator Module - Data Sources
# ==============================================================================

# ------------------------------------------------------------------------------
# AWS Account & Region Information
# ------------------------------------------------------------------------------

# Note: data.aws_region.current and data.aws_caller_identity.current
# are defined in locals.tf to avoid duplication

# ------------------------------------------------------------------------------
# Check for Existing Certificates in SSM
# ------------------------------------------------------------------------------

# Attempt to read existing server certificate ARN from SSM
# This determines whether we need to generate new certificates
# Use try() in locals to handle case when parameter doesn't exist (first deployment)
data "aws_ssm_parameter" "existing_server_arn" {
  count = 0 # Disabled - generate certificates on first deployment, then set to 1 after initial apply

  name = local.ssm_paths.server_arn
}

# Note: We only check server_arn because if it exists, all other parameters should exist too
# This is a conditional check pattern - if it fails, certificates don't exist yet
