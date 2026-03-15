# ==============================================================================
# Security Group Module - Local Values
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Pattern A: Common Prefix Transformations
  # ------------------------------------------------------------------------------

  # PascalCase prefix for resource names (e.g., "AcmeForgeDevSecurity")
  pascal_prefix = join("", [for part in split("-", var.common_prefix) : title(part)])

  # Path-like prefix (e.g., "/acme/forge/dev/security/")
  path_prefix = "/${replace(var.common_prefix, "-", "/")}/"

  # ------------------------------------------------------------------------------
  # Naming Construction with Validation and Sanitization
  # ------------------------------------------------------------------------------

  # Convert purpose to PascalCase for security group name
  # e.g., "eks-nodes" -> "EksNodes", "alb" -> "Alb"
  purpose_pascal = join("", [for part in split("-", var.purpose) : title(part)])

  # Security group name (PascalCase)
  sg_name = "${local.pascal_prefix}${local.purpose_pascal}Sg"

  # Step 1: Build raw name from components (kept for backward compatibility in description)
  raw_name = "sg-${var.purpose}-${var.common_prefix}"

  # Step 2: Sanitize - lowercase and replace invalid characters with hyphens
  sanitized_name = lower(replace(replace(local.raw_name, "/[^a-z0-9._\\-:/+=@ ]/", "-"), "/--+/", "-"))

  # Step 3: Apply AWS 255-character limit
  common_name = substr(local.sanitized_name, 0, 255)

  # Step 4: Validation checks
  name_validation = {
    length_ok      = length(local.common_name) <= 255
    pattern_ok     = can(regex("^[a-zA-Z0-9._\\-:/+=@ ]+$", local.common_name))
    no_double_dash = !can(regex("--", local.common_name))
    not_empty      = length(local.common_name) > 0
  }

  # ----------------------------------------------------------------------------
  # Nice description built from common prefix, ports, firewall tier/type
  # ----------------------------------------------------------------------------
  security_group_description = var.description != "" ? var.description : "Security group for ${var.common_prefix} handling connections on ports ${length(var.ports) > 0 ? join(", ", [for port in var.ports : tostring(port)]) : "all ports"} for a purpose of ${var.purpose}."

  # ------------------------------------------------------------------------------
  # Module Tags (Pattern A Compliance)
  # ------------------------------------------------------------------------------

  module_tags = {
    TerraformModule = "forge/aws/security/security-group"
    Module          = "SecurityGroup"
    Family          = "Networking"
    Purpose         = var.purpose
    Port            = length(var.ports) > 0 ? join(";", [for port in var.ports : tostring(port)]) : ""
  }

  # ------------------------------------------------------------------------------
  # Firewall Tags (Required for Security Group Chainer)
  # ------------------------------------------------------------------------------

  # ------------------------------------------------------------------------------
  # Final Tags
  # ------------------------------------------------------------------------------

  merged_tags = merge(
    local.module_tags,
    var.common_tags
  )
}