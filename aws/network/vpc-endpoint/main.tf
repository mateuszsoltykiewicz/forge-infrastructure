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
  vpc_endpoint_type = local.endpoint_type
  auto_accept       = true

  # Provide subnet IDs if required. Checks done using locals.tf validations made
  subnet_ids = local.subnets_required ? try(var.subnet_ids, null) : null

  # Provide security group IDs if required
  security_group_ids = local.security_group_required ? try([module.endpoint_security_group[0].security_group_id], null) : null

  # Interface endpoint configuration
  private_dns_enabled = local.is_interface_service ? true : null
  ip_address_type     = local.is_interface_service ? "ipv4" : null

  # Gateway endpoint configuration
  route_table_ids = local.route_tables_required ? var.route_table_ids : null

  # Policy
  policy = var.policy

  # DNS options (Interface endpoints only)
  dynamic "dns_options" {
    for_each = local.endpoint_type == "Interface" && try(var.dns_options, null) != null ? [var.dns_options] : []
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

    # Validate if local.endpoint_type is not "Unknown"
    precondition {
      condition     = local.endpoint_type_valid
      error_message = "Invalid service_name '${var.service_name}' for VPC Endpoint. Cannot determine endpoint type."
    }

    # Validate if local.has_subnets and raise error if not
    precondition {
      condition     = local.has_subnets
      error_message = "${local.endpoint_type} endpoints require subnet_ids to be specified"
    }

    # Validate if local.has_security_groups and raise error if not
    precondition {
      condition     = local.security_group_required ? length(module.endpoint_security_group) > 0 : true
      error_message = "Interface endpoints require security_group_ids to be specified"
    }

    # Validate if local.has_route_tables and raise error if not
    precondition {
      condition     = local.has_route_tables
      error_message = "Gateway endpoints require route_table_ids to be specified"
    }
  }

  depends_on = [module.endpoint_security_group]
}
