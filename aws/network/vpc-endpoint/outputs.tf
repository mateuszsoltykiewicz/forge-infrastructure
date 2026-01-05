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

output "state" {
  description = "State of the VPC endpoint"
  value       = aws_vpc_endpoint.this.state
}

output "vpc_id" {
  description = "ID of the VPC the endpoint belongs to"
  value       = aws_vpc_endpoint.this.vpc_id
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

output "security_group_ids" {
  description = "List of security group IDs (Interface endpoints)"
  value       = var.endpoint_type == "Interface" ? var.security_group_ids : []
}

output "private_dns_enabled" {
  description = "Whether private DNS is enabled (Interface endpoints)"
  value       = var.endpoint_type == "Interface" ? var.private_dns_enabled : null
}

output "ip_address_type" {
  description = "IP address type (Interface endpoints)"
  value       = var.endpoint_type == "Interface" ? var.ip_address_type : null
}

# ------------------------------------------------------------------------------
# DNS Configuration (Interface endpoints)
# ------------------------------------------------------------------------------

output "dns_entries" {
  description = "DNS entries for the endpoint (Interface endpoints)"
  value = aws_vpc_endpoint.this.dns_entry != null ? [
    for entry in aws_vpc_endpoint.this.dns_entry : {
      dns_name      = entry.dns_name
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
# Route Table Configuration (Gateway endpoints)
# ------------------------------------------------------------------------------

output "route_table_ids" {
  description = "List of route table IDs (Gateway endpoints)"
  value       = aws_vpc_endpoint.this.route_table_ids
}

output "prefix_list_id" {
  description = "Prefix list ID of the exposed service (Gateway endpoints)"
  value       = aws_vpc_endpoint.this.prefix_list_id
}

output "cidr_blocks" {
  description = "CIDR blocks of the exposed service (Gateway endpoints)"
  value       = aws_vpc_endpoint.this.cidr_blocks
}

# ------------------------------------------------------------------------------
# Policy
# ------------------------------------------------------------------------------

output "policy" {
  description = "IAM policy document attached to the endpoint"
  value       = aws_vpc_endpoint.this.policy
}

# ------------------------------------------------------------------------------
# Ownership
# ------------------------------------------------------------------------------

output "owner_id" {
  description = "AWS account ID of the endpoint owner"
  value       = aws_vpc_endpoint.this.owner_id
}

output "requester_managed" {
  description = "Whether the endpoint is managed by the requester"
  value       = aws_vpc_endpoint.this.requester_managed
}

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------

output "summary" {
  description = "Summary of VPC endpoint configuration"
  value = {
    name                = local.endpoint_name
    id                  = aws_vpc_endpoint.this.id
    arn                 = aws_vpc_endpoint.this.arn
    service_name        = aws_vpc_endpoint.this.service_name
    service_short_name  = local.service_short_name
    endpoint_type       = aws_vpc_endpoint.this.vpc_endpoint_type
    state               = aws_vpc_endpoint.this.state
    vpc_id              = aws_vpc_endpoint.this.vpc_id
    private_dns_enabled = var.endpoint_type == "Interface" ? var.private_dns_enabled : null
    subnet_count        = var.endpoint_type != "Gateway" ? length(var.subnet_ids) : 0
    route_table_count   = var.endpoint_type == "Gateway" ? length(var.route_table_ids) : 0
    architecture_type   = var.architecture_type
    environment         = var.environment
  }
}
