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
  vpn_name = substr("${var.common_prefix}-vpn", 0, 64)

  # CloudWatch Log Group name
  log_group_name = var.cloudwatch_log_group_name != null ? (
    var.cloudwatch_log_group_name
  ) : "/aws/vpn/${local.vpn_name}/connection-logs"

  # ------------------------------------------------------------------------------
  # VPN Configuration
  # ------------------------------------------------------------------------------

  # Automatic port selection based on protocol
  vpn_port = 443

  # DNS servers (use VPC DNS if not specified)
  dns_servers = length(var.dns_servers) > 0 ? var.dns_servers : null

  # ------------------------------------------------------------------------------
  # Security Groups
  # ------------------------------------------------------------------------------

  # ------------------------------------------------------------------------------
  # Tagging
  # ------------------------------------------------------------------------------

  module_tags = {
    TerraformModule = "forge/aws/security/client-vpn"
    Component       = "VPN"
    Service         = "AWS-Client-VPN"
  }

  merged_tags = merge(
    var.common_tags,
    local.module_tags
  )
}
