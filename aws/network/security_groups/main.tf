# ==============================================================================
# Security Groups Module - Main Resources
# ==============================================================================
# Creates security groups with ingress and egress rules for Forge infrastructure
# components (EKS, RDS, ALB, etc.).
# ==============================================================================

# ------------------------------------------------------------------------------
# Security Groups
# ------------------------------------------------------------------------------
# Creates AWS security groups in the specified VPC
# ------------------------------------------------------------------------------

resource "aws_security_group" "this" {
  for_each = var.security_groups

  name        = "${local.sg_name_prefix}-${each.key}"
  description = each.value.description
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.sg_name_prefix}-${each.key}"
      Purpose = each.key
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------
# Ingress Rules
# ------------------------------------------------------------------------------
# Creates ingress (inbound) rules for each security group
# ------------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for rule in local.ingress_rules : rule.rule_key => rule }

  security_group_id = aws_security_group.this[each.value.sg_name].id

  # Port and protocol configuration
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  ip_protocol = each.value.protocol

  # Source configuration (only one can be set)
  cidr_ipv4                    = each.value.cidr_blocks != null && length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks[0] : null
  cidr_ipv6                    = each.value.ipv6_cidr_blocks != null && length(each.value.ipv6_cidr_blocks) > 0 ? each.value.ipv6_cidr_blocks[0] : null
  referenced_security_group_id = each.value.source_security_group_id

  description = each.value.description

  tags = merge(
    local.common_tags,
    {
      Name      = each.value.rule_key
      Direction = "ingress"
      Protocol  = each.value.protocol
    }
  )
}

# ------------------------------------------------------------------------------
# Egress Rules
# ------------------------------------------------------------------------------
# Creates egress (outbound) rules for each security group
# ------------------------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = { for rule in local.egress_rules : rule.rule_key => rule }

  security_group_id = aws_security_group.this[each.value.sg_name].id

  # Port and protocol configuration
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  ip_protocol = each.value.protocol

  # Destination configuration (only one can be set)
  cidr_ipv4                    = each.value.cidr_blocks != null && length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks[0] : null
  cidr_ipv6                    = each.value.ipv6_cidr_blocks != null && length(each.value.ipv6_cidr_blocks) > 0 ? each.value.ipv6_cidr_blocks[0] : null
  referenced_security_group_id = each.value.source_security_group_id

  description = each.value.description

  tags = merge(
    local.common_tags,
    {
      Name      = each.value.rule_key
      Direction = "egress"
      Protocol  = each.value.protocol
    }
  )
}
