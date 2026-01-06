# ==============================================================================
# Internet Gateway Module - Outputs
# ==============================================================================
# Exposes Internet Gateway attributes for use by other modules.
# ==============================================================================

# ------------------------------------------------------------------------------
# Internet Gateway Outputs
# ------------------------------------------------------------------------------

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = var.create ? aws_internet_gateway.this[0].id : null
}

output "internet_gateway_arn" {
  description = "ARN of the Internet Gateway"
  value       = var.create ? aws_internet_gateway.this[0].arn : null
}

output "vpc_id" {
  description = "VPC ID that the Internet Gateway is attached to"
  value       = var.create ? aws_internet_gateway.this[0].vpc_id : null
}

# ------------------------------------------------------------------------------
# Route Configuration Outputs
# ------------------------------------------------------------------------------

output "public_route_table_id" {
  description = "Public route table ID where the default route was added"
  value       = var.public_route_table_id
}

output "default_route_id" {
  description = "ID of the default route (0.0.0.0/0) to the Internet Gateway"
  value       = aws_route.public_internet_access.id
}

# ------------------------------------------------------------------------------
# Customer Context Outputs
# ------------------------------------------------------------------------------

output "customer_id" {
  description = "Customer ID (null for shared infrastructure)"
  value       = var.customer_id
}

output "customer_name" {
  description = "Customer name (null for shared infrastructure)"
  value       = var.customer_name
}

output "architecture_type" {
  description = "Architecture type (shared, dedicated_local, dedicated_regional)"
  value       = var.architecture_type
}

# ------------------------------------------------------------------------------
# Configuration Summary
# ------------------------------------------------------------------------------

output "internet_gateway_summary" {
  description = "Summary of Internet Gateway configuration"
  value = {
    igw_id                = var.create ? aws_internet_gateway.this[0].id : null
    igw_name              = local.igw_name
    vpc_id                = var.vpc_id
    vpc_name              = var.vpc_name
    public_route_table_id = var.public_route_table_id
    default_route_created = true
    customer_id           = var.customer_id
    architecture_type     = var.architecture_type
  }
}
