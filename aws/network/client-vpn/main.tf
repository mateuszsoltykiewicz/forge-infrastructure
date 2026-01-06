# ==============================================================================
# AWS Client VPN Module - Main Configuration
# ==============================================================================
# This module creates an AWS Client VPN Endpoint for secure remote access to VPC.
# Features:
# - Multi-AZ high availability with network associations
# - Mutual TLS or Active Directory authentication
# - Split tunneling support
# - CloudWatch Logs integration
# - Auto-generated security groups
# ==============================================================================

# ------------------------------------------------------------------------------
# IAM Role for CloudWatch Logs
# ------------------------------------------------------------------------------

resource "aws_iam_role" "vpn_cloudwatch_logs" {
  count = var.enable_connection_logs ? 1 : 0

  name_prefix = "${local.vpn_name}-cloudwatch-logs-"
  description = "IAM role for AWS Client VPN to publish connection logs to CloudWatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "clientvpn.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpn_name}-cloudwatch-logs-role"
    }
  )
}

resource "aws_iam_role_policy" "vpn_cloudwatch_logs" {
  count = var.enable_connection_logs ? 1 : 0

  name_prefix = "${local.vpn_name}-cloudwatch-logs-"
  role        = aws_iam_role.vpn_cloudwatch_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = var.enable_connection_logs ? "${aws_cloudwatch_log_group.vpn_connection_logs[0].arn}:*" : "*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# AWS Client VPN Endpoint
# ------------------------------------------------------------------------------

resource "aws_ec2_client_vpn_endpoint" "this" {
  description = "AWS Client VPN Endpoint for ${local.vpn_name}"

  # Network Configuration
  client_cidr_block      = var.client_cidr_block
  server_certificate_arn = var.server_certificate_arn
  transport_protocol     = var.transport_protocol
  vpn_port               = local.vpn_port
  split_tunnel           = var.split_tunnel
  dns_servers            = local.dns_servers
  session_timeout_hours  = var.session_timeout_hours

  # Self-Service Portal
  self_service_portal = var.enable_self_service_portal ? "enabled" : "disabled"

  # Security Groups
  security_group_ids = length(local.security_group_ids) > 0 ? local.security_group_ids : null
  vpc_id             = var.vpc_id

  # Authentication Configuration
  authentication_options {
    type = var.authentication_type

    # Mutual TLS (Certificate-based authentication)
    root_certificate_chain_arn = var.authentication_type == "certificate-authentication" ? var.client_root_certificate_arn : null

    # Active Directory authentication
    active_directory_id = var.authentication_type == "directory-service-authentication" ? var.active_directory_id : null

    # SAML-based federated authentication
    saml_provider_arn          = var.authentication_type == "federated-authentication" ? var.saml_provider_arn : null
    self_service_saml_provider_arn = var.authentication_type == "federated-authentication" && var.enable_self_service_portal ? var.self_service_saml_provider_arn : null
  }

  # Connection Logging
  connection_log_options {
    enabled               = var.enable_connection_logs
    cloudwatch_log_group  = var.enable_connection_logs ? aws_cloudwatch_log_group.vpn_connection_logs[0].name : null
    cloudwatch_log_stream = var.enable_connection_logs ? aws_cloudwatch_log_stream.vpn_connection_stream[0].name : null
  }

  # Client Connect Handler (Lambda-based authorization)
  dynamic "client_connect_options" {
    for_each = var.client_connect_options.enabled ? [1] : []

    content {
      enabled             = true
      lambda_function_arn = var.client_connect_options.lambda_function_arn
    }
  }

  # Client Login Banner (future feature)
  # client_login_banner_options {
  #   enabled     = false
  #   banner_text = ""
  # }

  tags = merge(
    local.common_tags,
    {
      Name = local.vpn_name
    }
  )

  lifecycle {
    # Prevent accidental deletion of VPN endpoint
    prevent_destroy = false
  }
}

# ------------------------------------------------------------------------------
# VPN Endpoint Network Associations (Multi-AZ)
# ------------------------------------------------------------------------------

resource "aws_ec2_client_vpn_network_association" "this" {
  count = length(var.subnet_ids)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = var.subnet_ids[count.index]

  lifecycle {
    # Network associations must be created sequentially
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------
# VPN Routes (Automatic Route Propagation)
# ------------------------------------------------------------------------------

# Route to VPC CIDR block
resource "aws_ec2_client_vpn_route" "vpc_route" {
  count = length(var.subnet_ids)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  destination_cidr_block = var.vpc_cidr_block
  target_vpc_subnet_id   = aws_ec2_client_vpn_network_association.this[count.index].subnet_id
  description            = "Route to VPC CIDR block via subnet ${var.subnet_ids[count.index]}"

  depends_on = [aws_ec2_client_vpn_network_association.this]
}

# Additional routes for peered VPCs or on-premises networks (future enhancement)
# resource "aws_ec2_client_vpn_route" "additional_routes" {
#   for_each = var.additional_routes
#   ...
# }

# ==============================================================================
# AWS Client VPN Best Practices:
# ==============================================================================
# - Use mutual TLS (certificate-based) for development, AD/SAML for production
# - Enable split tunneling to reduce VPN bandwidth (only VPC traffic routes through VPN)
# - Deploy network associations in multiple AZs for high availability
# - Use CloudWatch Logs for audit trail and troubleshooting
# - Restrict security group rules to minimum required access
# - Set session timeout appropriately (24h max for production)
# - Use UDP transport for better performance (TCP as fallback)
# - Enable self-service portal for easy certificate management
# ==============================================================================
