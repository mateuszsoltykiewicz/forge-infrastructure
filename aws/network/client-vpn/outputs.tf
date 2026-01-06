# ==============================================================================
# AWS Client VPN Module - Outputs
# ==============================================================================

# ------------------------------------------------------------------------------
# VPN Endpoint Outputs
# ------------------------------------------------------------------------------

output "vpn_endpoint_id" {
  description = "ID of the AWS Client VPN endpoint"
  value       = var.create ? aws_ec2_client_vpn_endpoint.this[0].id : null
}

output "vpn_endpoint_arn" {
  description = "ARN of the AWS Client VPN endpoint"
  value       = var.create ? aws_ec2_client_vpn_endpoint.this[0].arn : null
}

output "vpn_endpoint_dns_name" {
  description = "DNS name of the VPN endpoint for client configuration"
  value       = var.create ? aws_ec2_client_vpn_endpoint.this[0].dns_name : null
}

output "vpn_name" {
  description = "Name of the VPN endpoint"
  value       = local.vpn_name
}

# ------------------------------------------------------------------------------
# Network Association Outputs
# ------------------------------------------------------------------------------

output "network_association_ids" {
  description = "IDs of VPN endpoint network associations"
  value       = aws_ec2_client_vpn_network_association.this[*].id
}

output "network_association_status" {
  description = "Status of network associations"
  value       = aws_ec2_client_vpn_network_association.this[*].status
}

# ------------------------------------------------------------------------------
# Security Group Outputs
# ------------------------------------------------------------------------------

output "security_group_id" {
  description = "ID of the VPN access security group (if created)"
  value       = var.create_security_group ? aws_security_group.vpn_access[0].id : null
}

output "security_group_arn" {
  description = "ARN of the VPN access security group (if created)"
  value       = var.create_security_group ? aws_security_group.vpn_access[0].arn : null
}

# ------------------------------------------------------------------------------
# Logging Outputs
# ------------------------------------------------------------------------------

output "cloudwatch_log_group_name" {
  description = "Name of CloudWatch Log Group for connection logs"
  value       = var.enable_connection_logs ? aws_cloudwatch_log_group.vpn_connection_logs[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of CloudWatch Log Group for connection logs"
  value       = var.enable_connection_logs ? aws_cloudwatch_log_group.vpn_connection_logs[0].arn : null
}

# ------------------------------------------------------------------------------
# Configuration Outputs
# ------------------------------------------------------------------------------

output "client_cidr_block" {
  description = "CIDR block assigned to VPN clients"
  value       = var.create ? aws_ec2_client_vpn_endpoint.this[0].client_cidr_block : null
}

output "transport_protocol" {
  description = "Transport protocol used by VPN endpoint"
  value       = var.create ? aws_ec2_client_vpn_endpoint.this[0].transport_protocol : null
}

output "vpn_port" {
  description = "VPN port number"
  value       = local.vpn_port
}

output "split_tunnel_enabled" {
  description = "Whether split tunneling is enabled"
  value       = var.create ? aws_ec2_client_vpn_endpoint.this[0].split_tunnel : null
}

# ------------------------------------------------------------------------------
# Summary Output
# ------------------------------------------------------------------------------

output "summary" {
  description = "Summary of VPN endpoint configuration"
  value = {
    vpn_endpoint_id       = var.create ? aws_ec2_client_vpn_endpoint.this[0].id : null
    vpn_endpoint_dns_name = var.create ? aws_ec2_client_vpn_endpoint.this[0].dns_name : null
    vpn_name              = local.vpn_name
    client_cidr_block     = var.create ? aws_ec2_client_vpn_endpoint.this[0].client_cidr_block : null
    transport_protocol    = var.create ? aws_ec2_client_vpn_endpoint.this[0].transport_protocol : null
    vpn_port              = local.vpn_port
    split_tunnel          = var.create ? aws_ec2_client_vpn_endpoint.this[0].split_tunnel : null
    authentication_type   = var.authentication_type
    network_associations  = length(aws_ec2_client_vpn_network_association.this)
    logging_enabled       = var.enable_connection_logs
    workspace             = var.workspace
    environment           = var.environment
    customer              = var.customer_name
    project               = var.project_name
  }
}
