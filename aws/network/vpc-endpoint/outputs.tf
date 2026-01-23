# ==============================================================================
# VPC Endpoint Module - Outputs
# ==============================================================================
# This file defines outputs for the VPC endpoint.
# ==============================================================================

# ------------------------------------------------------------------------------
# Endpoint Identification
# ------------------------------------------------------------------------------

output "endpoint_id" {
  description = "ID of the VPC endpoint"
  value       = aws_vpc_endpoint.this.id
}

output "endpoint_arn" {
  description = "ARN of the VPC endpoint"
  value       = aws_vpc_endpoint.this.arn
}

output "endpoint_name" {
  description = "Name of the VPC endpoint"
  value       = local.endpoint_name
}

# ------------------------------------------------------------------------------
# Endpoint Configuration
# ------------------------------------------------------------------------------

output "service_name" {
  description = "Full service name of the endpoint"
  value       = aws_vpc_endpoint.this.service_name
}

output "endpoint_type" {
  description = "Type of VPC endpoint"
  value       = aws_vpc_endpoint.this.vpc_endpoint_type
}

# ------------------------------------------------------------------------------
# Network Configuration (Interface endpoints)
# ------------------------------------------------------------------------------

output "network_interface_ids" {
  description = "List of network interface IDs (Interface endpoints only)"
  value       = aws_vpc_endpoint.this.network_interface_ids
}

output "subnet_ids" {
  description = "List of subnet IDs (Interface/GatewayLoadBalancer endpoints)"
  value       = aws_vpc_endpoint.this.subnet_ids
}

output "private_dns_enabled" {
  description = "Whether private DNS is enabled (Interface endpoints)"
  value       = local.endpoint_type == "Interface" ? true : null
}

output "ip_address_type" {
  description = "IP address type (Interface endpoints)"
  value       = local.endpoint_type == "Interface" ? "ipv4" : null
}

# ------------------------------------------------------------------------------
# DNS Configuration (Interface endpoints)
# ------------------------------------------------------------------------------

output "dns_entries" {
  description = "DNS entries for the endpoint (Interface endpoints)"
  value = aws_vpc_endpoint.this.dns_entry != null ? [
    for entry in aws_vpc_endpoint.this.dns_entry : {
      dns_name       = entry.dns_name
      hosted_zone_id = entry.hosted_zone_id
    }
  ] : []
}

output "dns_names" {
  description = "List of DNS names for the endpoint (Interface endpoints)"
  value = aws_vpc_endpoint.this.dns_entry != null ? [
    for entry in aws_vpc_endpoint.this.dns_entry : entry.dns_name
  ] : []
}

# ------------------------------------------------------------------------------
# Policy
# ------------------------------------------------------------------------------

output "policy" {
  description = "IAM policy document attached to the endpoint"
  value       = aws_vpc_endpoint.this.policy
}
