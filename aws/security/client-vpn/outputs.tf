# ==============================================================================
# AWS Client VPN Module - Outputs
# ==============================================================================

# ------------------------------------------------------------------------------
# VPN Endpoint Outputs
# ------------------------------------------------------------------------------

output "vpn_endpoint_id" {
  description = "ID of the AWS Client VPN endpoint"
  value       = aws_ec2_client_vpn_endpoint.this.id
}

output "vpn_endpoint_arn" {
  description = "ARN of the AWS Client VPN endpoint"
  value       = aws_ec2_client_vpn_endpoint.this.arn
}

output "vpn_endpoint_dns_name" {
  description = "DNS name of the VPN endpoint for client configuration"
  value       = aws_ec2_client_vpn_endpoint.this.dns_name
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

# ------------------------------------------------------------------------------
# Security Group Outputs
# ------------------------------------------------------------------------------

output "security_group_id" {
  description = "ID of the VPN access security group (if created)"
  value       = module.vpn_security_group.security_group_id
}

output "security_group_arn" {
  description = "ARN of the VPN access security group (if created)"
  value       = module.vpn_security_group.security_group_arn
}

# ------------------------------------------------------------------------------
# Logging Outputs
# ------------------------------------------------------------------------------

output "cloudwatch_log_group_name" {
  description = "Name of CloudWatch Log Group for connection logs"
  value       = aws_cloudwatch_log_group.vpn_connection_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of CloudWatch Log Group for connection logs"
  value       = aws_cloudwatch_log_group.vpn_connection_logs.arn
}

# ------------------------------------------------------------------------------
# Configuration Outputs
# ------------------------------------------------------------------------------

output "client_cidr_block" {
  description = "CIDR block assigned to VPN clients"
  value       = aws_ec2_client_vpn_endpoint.this.client_cidr_block
}

output "transport_protocol" {
  description = "Transport protocol used by VPN endpoint"
  value       = aws_ec2_client_vpn_endpoint.this.transport_protocol
}

output "vpn_port" {
  description = "VPN port number"
  value       = local.vpn_port
}

output "split_tunnel_enabled" {
  description = "Whether split tunneling is enabled"
  value       = aws_ec2_client_vpn_endpoint.this.split_tunnel
}

# ------------------------------------------------------------------------------
# Summary Output
# ------------------------------------------------------------------------------

output "summary" {
  description = "Summary of VPN endpoint configuration"
  value = {
    vpn_endpoint_id       = aws_ec2_client_vpn_endpoint.this.id
    vpn_endpoint_dns_name = aws_ec2_client_vpn_endpoint.this.dns_name
    vpn_name              = local.vpn_name
    client_cidr_block     = aws_ec2_client_vpn_endpoint.this.client_cidr_block
    transport_protocol    = aws_ec2_client_vpn_endpoint.this.transport_protocol
    vpn_port              = local.vpn_port
    split_tunnel          = aws_ec2_client_vpn_endpoint.this.split_tunnel
    authentication_type   = var.authentication_type
    network_associations  = length(aws_ec2_client_vpn_network_association.this)
    logging_enabled       = var.enable_connection_logs
  }
}

# ------------------------------------------------------------------------------
# Dashboard Outputs
# ------------------------------------------------------------------------------

output "dashboard_name" {
  description = "Name of CloudWatch Dashboard for VPN monitoring"
  value       = aws_cloudwatch_dashboard.vpn.dashboard_name
}

output "dashboard_url" {
  description = "URL to CloudWatch Dashboard in AWS Console"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.id}#dashboards:name=${aws_cloudwatch_dashboard.vpn.dashboard_name}"
}

# ------------------------------------------------------------------------------
# HIPAA Integration Outputs
# ------------------------------------------------------------------------------

output "hipaa_s3_export_enabled" {
  description = "Whether VPN logs are exported to HIPAA-compliant S3 bucket"
  value       = var.enable_hipaa_s3_export
}

output "subscription_filter_name" {
  description = "Name of CloudWatch subscription filter for HIPAA S3 export"
  value       = var.enable_hipaa_s3_export ? aws_cloudwatch_log_subscription_filter.vpn_to_kinesis[0].name : null
}

output "subscription_filter_id" {
  description = "ID of CloudWatch subscription filter"
  value       = var.enable_hipaa_s3_export ? aws_cloudwatch_log_subscription_filter.vpn_to_kinesis[0].id : null
}
