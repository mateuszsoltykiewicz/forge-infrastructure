# ==============================================================================
# VPN Certificate Generator Module - Local Values
# ==============================================================================
# This file defines local values for resource naming, tagging, and configuration.
# ==============================================================================

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {

  # ------------------------------------------------------------------------------
  # Pattern A: Common Prefix Transformations
  # ------------------------------------------------------------------------------

  # PascalCase prefix for resource names (e.g., "AcmeForgeDevSecurityVpnCerts")
  pascal_prefix = join("", [for part in split("-", var.common_prefix) : title(part)])

  # Path-like prefix for IAM roles (e.g., "/acme/forge/dev/security/")
  path_prefix = "/${replace(var.common_prefix, "-", "/")}/"

  # ------------------------------------------------------------------------------
  # SSM Parameter Store Paths
  # ------------------------------------------------------------------------------

  ssm_base_path = "${local.path_prefix}vpn/certificates"

  ssm_paths = {
    server_arn         = "${local.ssm_base_path}/server_arn"
    client_ca_arn      = "${local.ssm_base_path}/client_ca_arn"
    server_cert_pem    = "${local.ssm_base_path}/server_cert_pem"
    server_key_pem     = "${local.ssm_base_path}/server_key_pem"
    client_ca_cert_pem = "${local.ssm_base_path}/client_ca_cert_pem"
    client_ca_key_pem  = "${local.ssm_base_path}/client_ca_key_pem"
    expiration_date    = "${local.ssm_base_path}/expiration_date"
  }

  # DR region backup path (only CA private key)
  ssm_backup_path = "${local.ssm_base_path}/client_ca_key_pem_backup"

  # ------------------------------------------------------------------------------
  # Resource Naming (Pattern A - PascalCase)
  # ------------------------------------------------------------------------------

  kms_key_alias              = "${var.common_prefix}-vpn-certificates"
  kms_key_description        = "KMS key for VPN certificate encryption in SSM Parameter Store"
  iam_policy_name            = "${local.pascal_prefix}VpnCertificatesAccessPolicy"
  iam_policy_description     = "IAM policy for VPN certificate rotation job (Kubernetes/Lambda)"

  # ------------------------------------------------------------------------------
  # Certificate Configuration
  # ------------------------------------------------------------------------------

  # Certificate common name (FQDN)
  cert_common_name = var.cert_common_name != null ? var.cert_common_name : "vpn.${var.common_prefix}.internal"

  # Organization name for CA
  cert_org_name = var.cert_org_name != null ? var.cert_org_name : "Forge Platform"

  # ------------------------------------------------------------------------------
  # Conditional Logic
  # ------------------------------------------------------------------------------

  # Check if certificates already exist in SSM
  certificates_exist = try(data.aws_ssm_parameter.existing_server_arn[0].value, null) != null

  # Should we generate new certificates?
  should_generate_certs = !local.certificates_exist

  # ------------------------------------------------------------------------------
  # Tags
  # ------------------------------------------------------------------------------

  # Module-specific tags
  module_tags = {
    TerraformModule = "forge/aws/security/vpn-certificate-generator"
    Module          = "VPN Certificate Generator"
    Family          = "Security"
    Purpose         = "vpn-certificates"
  }

  # Merged tags
  merged_tags = merge(
    var.common_tags,
    local.module_tags
  )
}
