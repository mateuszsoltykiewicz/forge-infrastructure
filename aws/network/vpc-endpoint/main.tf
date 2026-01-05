# ==============================================================================
# VPC Endpoint Module - Main Resources
# ==============================================================================
# This file defines the VPC endpoint resource.
# ==============================================================================

# ------------------------------------------------------------------------------
# VPC Endpoint
# ------------------------------------------------------------------------------

resource "aws_vpc_endpoint" "this" {
  vpc_id            = var.vpc_id
  service_name      = local.full_service_name
  vpc_endpoint_type = var.endpoint_type
  auto_accept       = var.auto_accept

  # Interface and GatewayLoadBalancer endpoint configuration
  subnet_ids         = var.endpoint_type != "Gateway" ? var.subnet_ids : null
  security_group_ids = var.endpoint_type == "Interface" ? var.security_group_ids : null
  private_dns_enabled = var.endpoint_type == "Interface" ? var.private_dns_enabled : null
  ip_address_type    = var.endpoint_type == "Interface" ? var.ip_address_type : null

  # Gateway endpoint configuration
  route_table_ids = var.endpoint_type == "Gateway" ? var.route_table_ids : null

  # Policy
  policy = var.policy

  # DNS options (Interface endpoints only)
  dynamic "dns_options" {
    for_each = var.endpoint_type == "Interface" && var.dns_options != null ? [var.dns_options] : []
    content {
      dns_record_ip_type                             = dns_options.value.dns_record_ip_type
      private_dns_only_for_inbound_resolver_endpoint = dns_options.value.private_dns_only_for_inbound_resolver_endpoint
    }
  }

  tags = merge(
    local.merged_tags,
    {
      Name = local.endpoint_name
    }
  )

  lifecycle {
    create_before_destroy = true

    # Validate configuration based on endpoint type
    precondition {
      condition     = local.endpoint_type_valid
      error_message = "Endpoint type '${var.endpoint_type}' is not valid for service '${var.service_name}'. Gateway endpoints only support S3 and DynamoDB."
    }

    precondition {
      condition     = !local.requires_subnets || local.has_subnets
      error_message = "${var.endpoint_type} endpoints require subnet_ids to be specified"
    }

    precondition {
      condition     = !local.requires_security_groups || local.has_security_groups
      error_message = "Interface endpoints require security_group_ids to be specified"
    }

    precondition {
      condition     = !local.requires_route_tables || local.has_route_tables
      error_message = "Gateway endpoints require route_table_ids to be specified"
    }
  }
}
