# ==============================================================================
# AWS Client VPN Module - Authorization Rules
# ==============================================================================
# This file defines authorization rules that determine which network resources
# VPN clients can access after successful authentication.
# ==============================================================================

# ------------------------------------------------------------------------------
# Primary Authorization Rule - VPC Access
# ------------------------------------------------------------------------------

# Authorize access to entire VPC CIDR block
resource "aws_ec2_client_vpn_authorization_rule" "vpc_access" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = data.aws_vpc.main.cidr_block
  authorize_all_groups   = var.authorize_all_groups
  access_group_id        = var.authorize_all_groups ? null : var.access_group_id
  description            = "Allow VPN clients to access VPC CIDR ${data.aws_vpc.main.cidr_block}"
  depends_on             = [aws_ec2_client_vpn_network_association.this]
}

# ------------------------------------------------------------------------------
# Client-to-Client Communication (Optional)
# ------------------------------------------------------------------------------

# Allow VPN clients to communicate with each other
# Useful for remote collaboration, shared resources between team members
resource "aws_ec2_client_vpn_authorization_rule" "client_to_client" {
  count = var.split_tunnel ? 1 : 0

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = var.client_cidr_block
  authorize_all_groups   = var.authorize_all_groups
  access_group_id        = var.authorize_all_groups ? null : var.access_group_id
  description            = "Allow VPN client-to-client communication within ${var.client_cidr_block}"

  depends_on = [aws_ec2_client_vpn_network_association.this]
}

# ------------------------------------------------------------------------------
# Additional Authorization Rules (Custom Networks)
# ------------------------------------------------------------------------------

# Additional rules for specific CIDR blocks (e.g., peered VPCs, on-premises networks)
resource "aws_ec2_client_vpn_authorization_rule" "additional" {
  for_each = { for idx, rule in var.authorization_rules : idx => rule }

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = each.value.target_network_cidr
  authorize_all_groups   = each.value.access_group_id == null ? true : false
  access_group_id        = each.value.access_group_id
  description            = coalesce(each.value.description, "Additional access rule for ${each.value.target_network_cidr}")

  depends_on = [aws_ec2_client_vpn_network_association.this]
}

# ==============================================================================
# Authorization Rules Best Practices:
# ==============================================================================
# - Use authorize_all_groups = true for development/testing
# - Use Active Directory groups (access_group_id) for production
# - Keep authorization rules as specific as possible (principle of least privilege)
# - Enable client-to-client only if required (security consideration)
# - Use additional rules for peered VPCs or on-premises networks
# - Monitor CloudWatch Logs for unauthorized access attempts
# ==============================================================================
