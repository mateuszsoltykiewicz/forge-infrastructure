# ==============================================================================
# NAT Gateway Module - Outputs
# ==============================================================================
# Exposes NAT Gateway attributes for routing configuration in private subnets.
# ==============================================================================

# ------------------------------------------------------------------------------
# NAT Gateway Outputs
# ------------------------------------------------------------------------------

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs (one per AZ)"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of NAT Gateway public IP addresses (Elastic IPs)"
  value       = aws_eip.nat[*].public_ip
}

output "nat_gateway_private_ips" {
  description = "List of NAT Gateway private IP addresses"
  value       = aws_nat_gateway.this[*].private_ip
}

output "elastic_ip_ids" {
  description = "List of Elastic IP allocation IDs"
  value       = aws_eip.nat[*].id
}

output "nat_gateway_count" {
  description = "Number of NAT Gateways created"
  value       = length(aws_nat_gateway.this)
}

output "availability_zones" {
  description = "List of availability zones where NAT Gateways are deployed"
  value       = var.availability_zones
}

# ------------------------------------------------------------------------------
# Mapping Outputs (for round-robin routing)
# ------------------------------------------------------------------------------

output "nat_gateway_by_az" {
  description = "Map of AZ to NAT Gateway ID for round-robin routing"
  value = {
    for idx, az in var.availability_zones :
    az => aws_nat_gateway.this[idx].id
  }
}
