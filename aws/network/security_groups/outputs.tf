# ==============================================================================
# Security Groups Module - Outputs
# ==============================================================================
# Exposes security group IDs and details for use by other modules.
# ==============================================================================

# ------------------------------------------------------------------------------
# Security Group IDs
# ------------------------------------------------------------------------------

output "security_group_ids" {
  description = "Map of security group names to IDs"
  value = {
    for name, sg in aws_security_group.this : name => sg.id
  }
}

output "security_group_arns" {
  description = "Map of security group names to ARNs"
  value = {
    for name, sg in aws_security_group.this : name => sg.arn
  }
}

# ------------------------------------------------------------------------------
# Security Group Details
# ------------------------------------------------------------------------------

output "security_group_details" {
  description = "Detailed information about each security group"
  value = {
    for name, sg in aws_security_group.this : name => {
      id          = sg.id
      arn         = sg.arn
      name        = sg.name
      description = sg.description
      vpc_id      = sg.vpc_id
    }
  }
}

# ------------------------------------------------------------------------------
# Rule Counts
# ------------------------------------------------------------------------------

output "rule_counts" {
  description = "Count of ingress and egress rules per security group"
  value = {
    for name, sg_config in var.security_groups : name => {
      ingress_rules = length(sg_config.ingress_rules)
      egress_rules  = length(sg_config.egress_rules)
      total_rules   = length(sg_config.ingress_rules) + length(sg_config.egress_rules)
    }
  }
}

# ------------------------------------------------------------------------------
# Customer Context Outputs
# ------------------------------------------------------------------------------

output "customer_id" {
  description = "Customer ID (null for shared infrastructure)"
  value       = var.customer_id
}

output "customer_name" {
  description = "Customer name (null for shared infrastructure)"
  value       = var.customer_name
}

output "architecture_type" {
  description = "Architecture type (shared, dedicated_local, dedicated_regional)"
  value       = var.architecture_type
}

# ------------------------------------------------------------------------------
# Configuration Summary
# ------------------------------------------------------------------------------

output "security_groups_summary" {
  description = "Summary of security groups configuration"
  value = {
    vpc_id                  = var.vpc_id
    vpc_name                = var.vpc_name
    security_group_count    = length(var.security_groups)
    security_group_names    = keys(var.security_groups)
    total_ingress_rules     = length(local.ingress_rules)
    total_egress_rules      = length(local.egress_rules)
    customer_id             = var.customer_id
    architecture_type       = var.architecture_type
  }
}
