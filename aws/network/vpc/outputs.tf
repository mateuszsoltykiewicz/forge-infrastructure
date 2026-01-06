# ==============================================================================
# VPC Module Outputs (Forge - Customer-Centric)
# ==============================================================================

# ------------------------------------------------------------------------------
# VPC Identifiers
# ------------------------------------------------------------------------------

output "vpc_id" {
  value       = aws_vpc.this.id
  description = "The ID of the created VPC."
}

output "vpc_arn" {
  value       = aws_vpc.this.arn
  description = "The Amazon Resource Name (ARN) of the created VPC."
}

output "vpc_name" {
  value       = var.vpc_name
  description = "The name of the VPC."
}

output "cidr_block" {
  value       = var.cidr_block
  description = "The primary CIDR block of the VPC."
}

# ------------------------------------------------------------------------------
# Environment and Customer Context
# ------------------------------------------------------------------------------

output "workspace" {
  value       = var.workspace
  description = "The workspace associated with this VPC."
}

output "environment" {
  value       = var.environment
  description = "The environment associated with this VPC (prod, staging, dev)."
}

output "customer_id" {
  value       = var.customer_id
  description = "The customer UUID associated with this VPC (null for shared VPCs)."
}

output "customer_name" {
  value       = var.customer_name
  description = "The customer name associated with this VPC (null for shared VPCs)."
}

output "project_name" {
  value       = var.project_name
  description = "The project name associated with this VPC (null for non-project VPCs)."
}

# ------------------------------------------------------------------------------
# DNS Settings
# ------------------------------------------------------------------------------

output "enable_dns_support" {
  value       = aws_vpc.this.enable_dns_support
  description = "Whether DNS resolution is enabled in the VPC."
}

output "enable_dns_hostnames" {
  value       = aws_vpc.this.enable_dns_hostnames
  description = "Whether DNS hostnames are enabled in the VPC."
}

# ==============================================================================
# Multi-Tenant Outputs:
# ==============================================================================
# - Always output VPC ID and ARN for module composition
# - Include workspace, environment, customer, project for downstream modules
# - Outputs enable auto-discovery and dependency injection
# - Use outputs to pass VPC information to EKS, RDS, Redis, ALB modules
# ==============================================================================
