# ==============================================================================
# Security Groups Module - Local Values
# ==============================================================================
# Computes derived values for resource naming, tagging, and rule processing.
# ==============================================================================

locals {
  # Module identification
  module = "security_groups"
  family = "network"

  # Customer context
  is_customer_vpc = var.customer_id != null

  # Security group name prefix based on architecture type
  sg_name_prefix = var.architecture_type == "shared" ? (
    "${var.vpc_name}"
  ) : (
    "${var.customer_name}-${var.aws_region}"
  )

  # ------------------------------------------------------------------------------
  # Tagging Strategy
  # ------------------------------------------------------------------------------

  # Base tags (always applied)
  base_tags = {
    ManagedBy   = "Terraform"
    Module      = local.module
    Family      = local.family
    Workspace   = var.workspace
    Environment = var.environment
    Region      = var.aws_region
    VpcId       = var.vpc_id
  }

  # Customer-specific tags (only for dedicated VPCs)
  customer_tags = local.is_customer_vpc ? {
    CustomerId       = var.customer_id
    CustomerName     = var.customer_name
    ArchitectureType = var.architecture_type
    PlanTier         = var.plan_tier
  } : {}

  # Combined tags
  common_tags = merge(
    local.base_tags,
    local.customer_tags,
    var.common_tags
  )

  # ------------------------------------------------------------------------------
  # Rule Processing
  # ------------------------------------------------------------------------------

  # Flatten ingress rules for all security groups
  ingress_rules = flatten([
    for sg_name, sg_config in var.security_groups : [
      for idx, rule in sg_config.ingress_rules : {
        sg_name                  = sg_name
        rule_key                 = "${sg_name}-ingress-${idx}"
        from_port                = rule.from_port
        to_port                  = rule.to_port
        protocol                 = rule.protocol
        cidr_blocks              = rule.cidr_blocks
        ipv6_cidr_blocks         = rule.ipv6_cidr_blocks
        source_security_group_id = rule.source_security_group_id
        self                     = rule.self
        description              = rule.description
      }
    ]
  ])

  # Flatten egress rules for all security groups
  egress_rules = flatten([
    for sg_name, sg_config in var.security_groups : [
      for idx, rule in sg_config.egress_rules : {
        sg_name                  = sg_name
        rule_key                 = "${sg_name}-egress-${idx}"
        from_port                = rule.from_port
        to_port                  = rule.to_port
        protocol                 = rule.protocol
        cidr_blocks              = rule.cidr_blocks
        ipv6_cidr_blocks         = rule.ipv6_cidr_blocks
        source_security_group_id = rule.source_security_group_id
        self                     = rule.self
        description              = rule.description
      }
    ]
  ])
}
