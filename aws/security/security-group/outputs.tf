# ==============================================================================
# Security Group Module - Outputs
# ==============================================================================

output "security_group_id" {
  description = "ID of the created security group"
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "ARN of the created security group"
  value       = aws_security_group.this.arn
}

output "security_group_name" {
  description = "Name of the created security group"
  value       = aws_security_group.this.name
}

output "security_group_vpc_id" {
  description = "VPC ID of the security group"
  value       = aws_security_group.this.vpc_id
}

output "ports" {
  description = "List of ports handled by this security group"
  value       = var.ports
}

output "ingress_rule_count" {
  description = "Number of ingress rules created"
  value       = length(try(var.ingress_rules), [])
}

output "egress_rule_count" {
  description = "Number of egress rules created"
  value       = length(try(var.egress_rules), [])
}

output "ingress_rule_ids" {
  description = "Map of ingress rule identifiers"
  value       = try({ for k, v in aws_security_group_rule.ingress : k => v.id }, {})
}

output "egress_rule_ids" {
  description = "Map of egress rule identifiers"
  value       = try({ for k, v in aws_security_group_rule.egress : k => v.id }, {})
}