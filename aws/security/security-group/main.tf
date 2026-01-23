# ==============================================================================
# Security Group Module - Main Resources
# ==============================================================================

# ------------------------------------------------------------------------------
# Security Group
# ------------------------------------------------------------------------------

resource "aws_security_group" "this" {
  # Use either name or name_prefix (validated in locals)
  name                   = local.common_name
  description            = local.security_group_description
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = var.revoke_rules_on_delete

  tags = merge(
    local.merged_tags,
    {
      Name = local.common_name
    }
  )

  lifecycle {
    create_before_destroy = true

    # Validate security group name length
    precondition {
      condition     = local.name_validation.length_ok
      error_message = "Security Group name '${local.common_name}' exceeds 255 characters (length: ${length(local.common_name)})"
    }

    # Validate security group name pattern
    precondition {
      condition     = local.name_validation.pattern_ok
      error_message = "Security Group name '${local.common_name}' contains invalid characters. Allowed: a-zA-Z0-9._-:/+=@ and space"
    }

    # Validate no double hyphens
    precondition {
      condition     = local.name_validation.no_double_dash
      error_message = "Security Group name '${local.common_name}' contains double hyphens (--)"
    }

    # Validate name is not empty
    precondition {
      condition     = local.name_validation.not_empty
      error_message = "Security Group name cannot be empty"
    }
  }
}

# ------------------------------------------------------------------------------
# Ingress Rules
# ------------------------------------------------------------------------------

resource "aws_security_group_rule" "ingress" {
  for_each = {
    for idx, rule in var.ingress_rules :
    "${rule.protocol}-${rule.from_port}-${rule.to_port}-${idx}" => rule
  }

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description != "" ? each.value.description : null
  security_group_id = aws_security_group.this.id

  # Source configuration (mutually exclusive - only ONE can be set)
  # AWS requires that cidr_blocks, ipv6_cidr_blocks, source_security_group_id, and self are mutually exclusive
  # When self=true, all other source attributes must be null
  # When self=false, self must be null (not false) to avoid conflict
  cidr_blocks              = each.value.self ? null : (length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null)
  ipv6_cidr_blocks         = each.value.self ? null : (length(each.value.ipv6_cidr_blocks) > 0 ? each.value.ipv6_cidr_blocks : null)
  source_security_group_id = each.value.self ? null : each.value.source_security_group_id
  self                     = each.value.self ? true : null

  lifecycle {
    # Ensure at least one source is specified
    precondition {
      condition = (
        length(each.value.cidr_blocks) > 0 ||
        length(each.value.ipv6_cidr_blocks) > 0 ||
        each.value.source_security_group_id != null ||
        each.value.self == true
      )
      error_message = "At least one source must be specified (cidr_blocks, ipv6_cidr_blocks, source_security_group_id, or self)"
    }
  }
}

# ------------------------------------------------------------------------------
# Egress Rules
# ------------------------------------------------------------------------------

resource "aws_security_group_rule" "egress" {
  for_each = {
    for idx, rule in var.egress_rules :
    "${rule.protocol}-${rule.from_port}-${rule.to_port}-${idx}" => rule
  }

  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description != "" ? each.value.description : null
  security_group_id = aws_security_group.this.id

  # Destination configuration (mutually exclusive - only ONE can be set)
  # AWS requires that cidr_blocks, ipv6_cidr_blocks, source_security_group_id, and self are mutually exclusive
  # When self=true, all other destination attributes must be null
  # When self=false, self must be null (not false) to avoid conflict
  cidr_blocks              = each.value.self ? null : (length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null)
  ipv6_cidr_blocks         = each.value.self ? null : (length(each.value.ipv6_cidr_blocks) > 0 ? each.value.ipv6_cidr_blocks : null)
  source_security_group_id = each.value.self ? null : each.value.source_security_group_id
  self                     = each.value.self ? true : null

  lifecycle {
    # Ensure at least one destination is specified
    precondition {
      condition = (
        length(each.value.cidr_blocks) > 0 ||
        length(each.value.ipv6_cidr_blocks) > 0 ||
        each.value.source_security_group_id != null ||
        each.value.self == true
      )
      error_message = "At least one destination must be specified (cidr_blocks, ipv6_cidr_blocks, source_security_group_id, or self)"
    }
  }
}