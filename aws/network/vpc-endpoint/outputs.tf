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
  value       = var.create ? aws_vpc_endpoint.this[0].id : null
}

output "endpoint_arn" {
  description = "ARN of the VPC endpoint"
  value       = var.create ? aws_vpc_endpoint.this[0].arn : null
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
  value       = var.create ? aws_vpc_endpoint.this[0].service_name : null
}

output "endpoint_type" {
  description = "Type of VPC endpoint"
  value       = var.create ? aws_vpc_endpoint.this[0].vpc_endpoint_type : null
}

output "state" {
  description = "State of the VPC endpoint"
  value       = var.create ? aws_vpc_endpoint.this[0].state : null
}

output "vpc_id" {
  description = "ID of the VPC the endpoint belongs to"
  value       = var.create ? aws_vpc_endpoint.this[0].vpc_id : null
}

# ------------------------------------------------------------------------------
# Network Configuration (Interface endpoints)
# ------------------------------------------------------------------------------

output "network_interface_ids" {
  description = "List of network interface IDs (Interface endpoints only)"
  value       = var.create ? aws_vpc_endpoint.this[0].network_interface_ids : null
}

output "subnet_ids" {
  description = "List of subnet IDs (Interface/GatewayLoadBalancer endpoints)"
  value       = var.create ? aws_vpc_endpoint.this[0].subnet_ids : null
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
  value = var.create ? aws_vpc_endpoint.this[0].dns_entry : null != null ? [
    for entry in var.create ? aws_vpc_endpoint.this[0].dns_entry : null : {
      dns_name       = entry.dns_name
      hosted_zone_id = entry.hosted_zone_id
    }
  ] : []
}

output "dns_names" {
  description = "List of DNS names for the endpoint (Interface endpoints)"
  value = var.create ? aws_vpc_endpoint.this[0].dns_entry : null != null ? [
    for entry in var.create ? aws_vpc_endpoint.this[0].dns_entry : null : entry.dns_name
  ] : []
}

# ------------------------------------------------------------------------------
# Route Table Configuration (Gateway endpoints)
# ------------------------------------------------------------------------------

output "route_table_ids" {
  description = "List of route table IDs (Gateway endpoints)"
  value       = var.create ? aws_vpc_endpoint.this[0].route_table_ids : null
}

output "prefix_list_id" {
  description = "Prefix list ID of the exposed service (Gateway endpoints)"
  value       = var.create ? aws_vpc_endpoint.this[0].prefix_list_id : null
}

output "cidr_blocks" {
  description = "CIDR blocks of the exposed service (Gateway endpoints)"
  value       = var.create ? aws_vpc_endpoint.this[0].cidr_blocks : null
}

# ------------------------------------------------------------------------------
# Policy
# ------------------------------------------------------------------------------

output "policy" {
  description = "IAM policy document attached to the endpoint"
  value       = var.create ? aws_vpc_endpoint.this[0].policy : null
}

# ------------------------------------------------------------------------------
# Ownership
# ------------------------------------------------------------------------------

output "owner_id" {
  description = "AWS account ID of the endpoint owner"
  value       = var.create ? aws_vpc_endpoint.this[0].owner_id : null
}

output "requester_managed" {
  description = "Whether the endpoint is managed by the requester"
  value       = var.create ? aws_vpc_endpoint.this[0].requester_managed : null
}

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------

output "summary" {
  description = "Summary of VPC endpoint configuration"
  value = {
    name                = local.endpoint_name
    id                  = var.create ? aws_vpc_endpoint.this[0].id : null
    arn                 = var.create ? aws_vpc_endpoint.this[0].arn : null
    service_name        = var.create ? aws_vpc_endpoint.this[0].service_name : null
    service_short_name  = local.service_short_name
    endpoint_type       = var.create ? aws_vpc_endpoint.this[0].vpc_endpoint_type : null
    state               = var.create ? aws_vpc_endpoint.this[0].state : null
    vpc_id              = var.create ? aws_vpc_endpoint.this[0].vpc_id : null
    private_dns_enabled = var.endpoint_type == "Interface" ? var.private_dns_enabled : null
    subnet_count        = var.endpoint_type != "Gateway" ? length(var.subnet_ids) : 0
    route_table_count   = var.endpoint_type == "Gateway" ? length(var.route_table_ids) : 0
    workspace           = var.workspace
    customer            = var.customer_name
    project             = var.project_name
    environment         = var.environment
  }
}
