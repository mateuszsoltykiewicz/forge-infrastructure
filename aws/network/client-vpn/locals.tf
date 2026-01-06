# ==============================================================================
# AWS Client VPN Module - Local Values
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Naming Convention (3-scenario pattern)
  # ------------------------------------------------------------------------------

  # VPN endpoint name based on customer/project context
  # 1. Shared: forge-{environment}-vpn
  # 2. Customer-dedicated: forge-{environment}-{customer}-vpn
  # 3. Project-isolated: forge-{environment}-{customer}-{project}-vpn
  vpn_name = var.customer_name != null && var.project_name != null ? (
    "forge-${var.environment}-${var.customer_name}-${var.project_name}-vpn"
    ) : var.customer_name != null ? (
    "forge-${var.environment}-${var.customer_name}-vpn"
  ) : "forge-${var.environment}-vpn"

  # Security group name
  security_group_name = var.security_group_name != null ? (
    var.security_group_name
  ) : "${local.vpn_name}-access-sg"

  # CloudWatch Log Group name
  log_group_name = var.cloudwatch_log_group_name != null ? (
    var.cloudwatch_log_group_name
  ) : "/aws/vpn/${local.vpn_name}/connection-logs"

  # ------------------------------------------------------------------------------
  # VPN Configuration
  # ------------------------------------------------------------------------------

  # Automatic port selection based on protocol
  vpn_port = var.vpn_port != null ? var.vpn_port : (
    var.transport_protocol == "tcp" ? 443 : 1194
  )

  # DNS servers (use VPC DNS if not specified)
  dns_servers = length(var.dns_servers) > 0 ? var.dns_servers : null

  # ------------------------------------------------------------------------------
  # Security Groups
  # ------------------------------------------------------------------------------

  # Determine security group IDs to use
  security_group_ids = var.create_security_group ? (
    concat([aws_security_group.vpn_access[0].id], var.security_group_ids)
  ) : var.security_group_ids

  # ------------------------------------------------------------------------------
  # Tagging
  # ------------------------------------------------------------------------------

  merged_tags = merge(
    var.tags,
    {
      Workspace   = var.workspace
      Environment = var.environment
      Component   = "VPN"
      Service     = "AWS-Client-VPN"
      ManagedBy   = "Terraform"
    },
    var.customer_name != null ? { Customer = var.customer_name } : {},
    var.project_name != null ? { Project = var.project_name } : {}
  )
}
