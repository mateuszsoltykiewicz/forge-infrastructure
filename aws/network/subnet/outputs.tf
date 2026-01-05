# ==============================================================================
# Subnet Module Outputs (Forge - Customer-Centric)
# ==============================================================================

# ------------------------------------------------------------------------------
# Subnet IDs
# ------------------------------------------------------------------------------

output "subnet_ids" {
  description = "Map of subnet names to their AWS subnet IDs"
  value = {
    for name, subnet in aws_subnet.this : name => subnet.id
  }
}

output "subnet_ids_list" {
  description = "List of all subnet IDs (for use with count-based resources)"
  value       = [for subnet in aws_subnet.this : subnet.id]
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value = [
    for name, subnet in aws_subnet.this : subnet.id
    if lower(var.subnets[index(var.subnets.*.name, name)].tier) == "public"
  ]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = [
    for name, subnet in aws_subnet.this : subnet.id
    if lower(var.subnets[index(var.subnets.*.name, name)].tier) == "private"
  ]
}

# ------------------------------------------------------------------------------
# Subnet Details
# ------------------------------------------------------------------------------

output "subnet_details" {
  description = "Detailed information about each subnet"
  value = {
    for name, subnet in aws_subnet.this : name => {
      id                      = subnet.id
      arn                     = subnet.arn
      cidr_block              = subnet.cidr_block
      availability_zone       = subnet.availability_zone
      availability_zone_id    = subnet.availability_zone_id
      map_public_ip_on_launch = subnet.map_public_ip_on_launch
      vpc_id                  = subnet.vpc_id
      tier                    = subnet.tags["Tier"]
      purpose                 = subnet.tags["Purpose"]
    }
  }
}

# ------------------------------------------------------------------------------
# Subnets Grouped by Tier
# ------------------------------------------------------------------------------

output "subnets_by_tier" {
  description = "Subnets grouped by tier (Public/Private)"
  value = {
    public = {
      for name, subnet in aws_subnet.this : name => subnet.id
      if lower(var.subnets[index(var.subnets.*.name, name)].tier) == "public"
    }
    private = {
      for name, subnet in aws_subnet.this : name => subnet.id
      if lower(var.subnets[index(var.subnets.*.name, name)].tier) == "private"
    }
  }
}

# ------------------------------------------------------------------------------
# Subnets Grouped by Purpose
# ------------------------------------------------------------------------------

output "subnets_by_purpose" {
  description = "Subnets grouped by purpose (eks, database, application, etc.)"
  value = {
    for purpose in distinct([for s in var.subnets : s.purpose]) : purpose => {
      for name, subnet in aws_subnet.this : name => subnet.id
      if var.subnets[index(var.subnets.*.name, name)].purpose == purpose
    }
  }
}

# ------------------------------------------------------------------------------
# Subnets Grouped by Availability Zone
# ------------------------------------------------------------------------------

output "subnets_by_az" {
  description = "Subnets grouped by availability zone"
  value = {
    for az in distinct([for s in var.subnets : s.availability_zone]) : az => {
      for name, subnet in aws_subnet.this : name => subnet.id
      if var.subnets[index(var.subnets.*.name, name)].availability_zone == az
    }
  }
}

# ------------------------------------------------------------------------------
# Route Table IDs
# ------------------------------------------------------------------------------

output "route_table_ids" {
  description = "Map of route table types to their IDs"
  value = merge(
    local.has_public_subnets ? { "public" = aws_route_table.public[0].id } : {},
    local.has_private_subnets ? { "private" = aws_route_table.private[0].id } : {}
  )
}

output "public_route_table_id" {
  description = "Public route table ID (null if no public subnets)"
  value       = local.has_public_subnets ? aws_route_table.public[0].id : null
}

output "private_route_table_id" {
  description = "Private route table ID (null if no private subnets)"
  value       = local.has_private_subnets ? aws_route_table.private[0].id : null
}

# ------------------------------------------------------------------------------
# VPC Information
# ------------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID containing these subnets"
  value       = var.vpc_id
}

output "vpc_name" {
  description = "VPC name"
  value       = var.vpc_name
}

# ------------------------------------------------------------------------------
# Configuration Summary
# ------------------------------------------------------------------------------

output "subnet_configuration_summary" {
  description = "Summary of subnet configuration"
  value = {
    total_subnets      = length(var.subnets)
    public_subnets     = length(local.public_purposes)
    private_subnets    = length(local.private_purposes)
    availability_zones = distinct([for s in var.subnets : s.availability_zone])
    purposes           = distinct([for s in var.subnets : s.purpose])
    tiers              = distinct([for s in var.subnets : s.tier])
  }
}

# ------------------------------------------------------------------------------
# Customer Context
# ------------------------------------------------------------------------------

output "customer_id" {
  description = "Customer UUID (null for shared infrastructure)"
  value       = var.customer_id
}

output "customer_name" {
  description = "Customer name (null for shared infrastructure)"
  value       = var.customer_name
}

output "architecture_type" {
  description = "Architecture deployment model"
  value       = var.architecture_type
}

# ==============================================================================
# Forge Best Practices:
# ==============================================================================
# - Use subnet_ids map for name-based lookups
# - Use public_subnet_ids/private_subnet_ids lists for EKS, ALB, etc.
# - Use subnets_by_purpose for organizing resources by function
# - Use subnets_by_az for multi-AZ deployments
# ==============================================================================
