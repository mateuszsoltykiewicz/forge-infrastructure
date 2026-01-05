# ==============================================================================
# VPC Endpoint Module - Local Values
# ==============================================================================
# This file defines local values for computed resource attributes.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Architecture Detection
  # ------------------------------------------------------------------------------

  # Determine if this is shared or dedicated architecture
  is_shared_architecture = var.architecture_type == "shared"

  # ------------------------------------------------------------------------------
  # Service Name Processing
  # ------------------------------------------------------------------------------

  # Determine if this is a standard AWS service or PrivateLink service
  is_aws_service = !can(regex("^com\\.amazonaws\\.vpce\\.", var.service_name))
  
  # Extract service short name (e.g., "s3" from "s3" or "ec2" from "ec2")
  # For AWS services, use the service name directly
  # For PrivateLink, extract from the service ID
  service_short_name = local.is_aws_service ? var.service_name : "privatelink"

  # Build full service name for AWS services (com.amazonaws.region.service)
  # For PrivateLink services, use the provided service name as-is
  full_service_name = local.is_aws_service ? (
    "com.amazonaws.${var.region}.${var.service_name}"
  ) : var.service_name

  # ------------------------------------------------------------------------------
  # Endpoint Naming
  # ------------------------------------------------------------------------------

  # Shared architecture: forge-{environment}-{service}-vpce
  # Dedicated architecture: {customer_name}-{region}-{service}-vpce
  endpoint_name = local.is_shared_architecture ? (
    "forge-${var.environment}-${local.service_short_name}-vpce"
  ) : (
    "${var.customer_name}-${var.region}-${local.service_short_name}-vpce"
  )

  # ------------------------------------------------------------------------------
  # Endpoint Type Validation
  # ------------------------------------------------------------------------------

  # Gateway endpoints only support S3 and DynamoDB
  is_gateway_service = contains(["s3", "dynamodb"], var.service_name)
  
  # Validate endpoint type matches service
  endpoint_type_valid = (
    (var.endpoint_type == "Gateway" && local.is_gateway_service) ||
    (var.endpoint_type != "Gateway" && !local.is_gateway_service) ||
    (var.endpoint_type == "Interface" && local.is_gateway_service)  # Interface works for all services
  )

  # ------------------------------------------------------------------------------
  # Configuration Validation
  # ------------------------------------------------------------------------------

  # Interface/GWLB endpoints require subnet_ids
  requires_subnets = contains(["Interface", "GatewayLoadBalancer"], var.endpoint_type)
  has_subnets = length(var.subnet_ids) > 0

  # Interface endpoints require security_group_ids
  requires_security_groups = var.endpoint_type == "Interface"
  has_security_groups = length(var.security_group_ids) > 0

  # Gateway endpoints require route_table_ids
  requires_route_tables = var.endpoint_type == "Gateway"
  has_route_tables = length(var.route_table_ids) > 0

  # ------------------------------------------------------------------------------
  # Tagging Strategy
  # ------------------------------------------------------------------------------

  # Base tags applied to all resources
  base_tags = {
    Environment     = var.environment
    ManagedBy       = "terraform"
    TerraformModule = "network/vpc-endpoint"
    Region          = var.region
    ServiceName     = local.service_short_name
    EndpointType    = var.endpoint_type
  }

  # Customer-specific tags (only applied for dedicated architectures)
  customer_tags = !local.is_shared_architecture ? {
    CustomerId       = var.customer_id
    CustomerName     = var.customer_name
    ArchitectureType = var.architecture_type
    PlanTier         = var.plan_tier
  } : {}

  # Merge all tags
  merged_tags = merge(
    local.base_tags,
    local.customer_tags,
    var.tags
  )
}
