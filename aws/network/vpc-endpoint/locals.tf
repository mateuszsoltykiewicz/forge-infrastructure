# ==============================================================================
# VPC Endpoint Module - Local Values
# ==============================================================================
# This file defines local values for computed resource attributes.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Multi-Tenant Detection
  # ------------------------------------------------------------------------------

  # Determine tenancy level
  has_customer = var.customer_name != null
  has_project  = var.project_name != null

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
  # Endpoint Naming (Multi-Tenant Pattern)
  # ------------------------------------------------------------------------------

  # Three scenarios:
  # 1. Shared: forge-{environment}-{service}-vpce
  # 2. Customer: forge-{environment}-{customer}-{service}-vpce
  # 3. Project: forge-{environment}-{customer}-{project}-{service}-vpce

  name_prefix = local.has_project ? "forge-${var.environment}-${var.customer_name}-${var.project_name}" : (
    local.has_customer ? "forge-${var.environment}-${var.customer_name}" : "forge-${var.environment}"
  )

  endpoint_name = "${local.name_prefix}-${local.service_short_name}-vpce"

  # ------------------------------------------------------------------------------
  # Endpoint Type Validation
  # ------------------------------------------------------------------------------

  # Gateway endpoints only support S3 and DynamoDB
  is_gateway_service = contains(["s3", "dynamodb"], var.service_name)

  # Validate endpoint type matches service
  endpoint_type_valid = (
    (var.endpoint_type == "Gateway" && local.is_gateway_service) ||
    (var.endpoint_type != "Gateway" && !local.is_gateway_service) ||
    (var.endpoint_type == "Interface" && local.is_gateway_service) # Interface works for all services
  )

  # ------------------------------------------------------------------------------
  # Configuration Validation
  # ------------------------------------------------------------------------------

  # Interface/GWLB endpoints require subnet_ids
  requires_subnets = contains(["Interface", "GatewayLoadBalancer"], var.endpoint_type)
  has_subnets      = length(var.subnet_ids) > 0

  # Interface endpoints require security_group_ids
  requires_security_groups = var.endpoint_type == "Interface"
  has_security_groups      = length(var.security_group_ids) > 0

  # Gateway endpoints require route_table_ids
  requires_route_tables = var.endpoint_type == "Gateway"
  has_route_tables      = length(var.route_table_ids) > 0

  # ------------------------------------------------------------------------------
  # Tagging Strategy (Multi-Tenant)
  # ------------------------------------------------------------------------------

  # Base tags applied to all resources
  base_tags = {
    Environment     = var.environment
    ManagedBy       = "Terraform"
    TerraformModule = "network/vpc-endpoint"
    Workspace       = var.workspace
    ServiceName     = local.service_short_name
    EndpointType    = var.endpoint_type
  }

  # Customer and project tags (conditional)
  customer_tags = local.has_customer ? {
    Customer = var.customer_name
  } : {}

  project_tags = local.has_project ? {
    Project = var.project_name
  } : {}

  # Merge all tags
  merged_tags = merge(
    local.base_tags,
    local.customer_tags,
    local.project_tags,
    var.tags
  )
}
