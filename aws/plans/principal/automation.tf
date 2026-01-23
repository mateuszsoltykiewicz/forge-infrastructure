# ==============================================================================
# Automation - Security Group & Configuration Management
# ==============================================================================
# Automated security group chaining and SSM Parameter Store synchronization
# ==============================================================================

# ------------------------------------------------------------------------------
# Local: Merged Chains Configuration
# ------------------------------------------------------------------------------
# Combine base chains with VPN chains (conditional on VPN deployment)
# ------------------------------------------------------------------------------

locals {
  # Load base chains (always present)
  base_chains = yamldecode(file("${path.root}/config/chains-base.yaml"))

  # Load VPN chains (only if VPN is deployed)
  vpn_chains_raw  = var.vpn_server_certificate_arn != null ? yamldecode(file("${path.root}/config/chains-vpn.yaml")) : null
  vpn_chains_list = var.vpn_server_certificate_arn != null ? local.vpn_chains_raw.chains : []

  # Merge chains
  merged_chains = {
    version                   = local.base_chains.version
    timeout_seconds           = local.base_chains.timeout_seconds
    polling_interval_seconds  = local.base_chains.polling_interval_seconds
    circuit_breaker_threshold = local.base_chains.circuit_breaker_threshold
    chains                    = concat(local.base_chains.chains, local.vpn_chains_list)
  }

  # YAML string for upload to SSM
  merged_chains_yaml = yamlencode(local.merged_chains)
}

# ------------------------------------------------------------------------------
# YAML to SSM Sync - Security Group Chains Configuration
# ------------------------------------------------------------------------------
# Uploads merged chains configuration to SSM Parameter Store
# Parameter: /forge/security-group-chains
# ------------------------------------------------------------------------------

# Write merged chains to temporary file
resource "local_file" "merged_chains" {
  content  = local.merged_chains_yaml
  filename = "${path.root}/config/.generated/chains-merged.yaml"
}

module "yaml_ssm_sync_chains" {
  source = "../../security/yaml-sync-with-ssm"

  common_prefix = local.common_prefix
  common_tags   = local.merged_tags

  sync_mode              = "upload"
  yaml_file_path         = local_file.merged_chains.filename
  ssm_parameter_name     = "/forge/security-group-chains"
  aws_region             = local.current_region
  validate_before_upload = true
  force_sync             = false
  trigger_on_yaml_change = false

  parameter_description = "Security Group Chains Configuration - Managed by Terraform (VPN: ${var.vpn_server_certificate_arn != null ? "enabled" : "disabled"})"

  depends_on = [local_file.merged_chains]
}

# ------------------------------------------------------------------------------
# Security Group Chainer - Run Separately After Terraform Apply
# ------------------------------------------------------------------------------
# The security-group-chainer creates circular dependencies with EKS:
# - EKS needs security group rules to start (control-plane ↔ worker-nodes)
# - Chainer needs EKS security groups to exist before it can add rules
#
# SOLUTION: Run chainer as standalone process AFTER terraform apply completes
# Usage: ./scripts/apply-security-chains.sh
# ------------------------------------------------------------------------------
