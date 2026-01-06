# ==============================================================================
# EKS Module - Usage Examples (Multi-Tenant)
# ==============================================================================
# This file contains commented examples showing different deployment scenarios
# ==============================================================================

# ------------------------------------------------------------------------------
# Example 1: Shared Platform Cluster (Multi-Tenant)
# ------------------------------------------------------------------------------
# Cluster Name: forge-production-eks
# Use Case: Multiple customers in a single cluster using namespaces
# ------------------------------------------------------------------------------

/*
module "eks_shared" {
  source = "./eks"

  # Auto-discovery VPC (shared platform VPC)
  workspace   = "production"
  environment = "production"
  aws_region  = "eu-west-1"

  # Cluster Configuration
  kubernetes_version = "1.31"

  # Shared cluster - no customer/project tags
  architecture_type = "shared"

  # NAT Gateway for initial setup (disable later to save $32/month per NAT)
  enable_nat_gateway = true

  # Subnet configuration
  eks_subnet_az_count      = 3
  eks_subnet_newbits       = 3  # /19 subnets from /16 VPC
  eks_subnet_netnum_start  = 4

  # System node group
  system_node_desired_size = 3
  system_node_min_size     = 2
  system_node_max_size     = 5
  system_node_instance_types = ["m7g.large", "m7g.xlarge"]

  tags = {
    Team = "Platform"
    Cost = "Shared"
  }
}
*/

# ------------------------------------------------------------------------------
# Example 2: Customer-Dedicated Cluster (Single Customer)
# ------------------------------------------------------------------------------
# Cluster Name: acme-corp-eu-west-1-eks
# Use Case: Dedicated cluster for a single customer (all projects)
# ------------------------------------------------------------------------------

/*
module "eks_customer" {
  source = "./eks"

  # Auto-discovery VPC (customer-specific VPC)
  workspace   = "production"
  environment = "production"
  aws_region  = "eu-west-1"

  # Customer identification
  customer_id   = "CUST001"
  customer_name = "acme-corp"

  # Multi-tenant tags (Customer only)
  # VPC will be discovered with tags: Customer=acme-corp

  # Cluster Configuration
  kubernetes_version = "1.31"
  architecture_type  = "dedicated_local"
  plan_tier         = "enterprise"

  # NAT Gateway
  enable_nat_gateway = true

  # Subnet configuration
  eks_subnet_az_count      = 3
  eks_subnet_newbits       = 3
  eks_subnet_netnum_start  = 4

  # System node group
  system_node_desired_size   = 3
  system_node_min_size       = 2
  system_node_max_size       = 10
  system_node_instance_types = ["m7g.xlarge", "m7g.2xlarge"]

  tags = {
    CostCenter = "ACME-INFRA"
  }
}
*/

# ------------------------------------------------------------------------------
# Example 3: Customer + Project Cluster (Multiple Projects per Customer)
# ------------------------------------------------------------------------------
# Cluster Name: acme-corp-web-platform-eu-west-1-eks
# Use Case: Dedicated cluster for a specific customer project
# ------------------------------------------------------------------------------

/*
module "eks_project" {
  source = "./eks"

  # Auto-discovery VPC (project-specific VPC)
  workspace   = "production"
  environment = "production"
  aws_region  = "eu-west-1"

  # Multi-tenant identification
  customer_id   = "CUST001"
  customer_name = "acme-corp"
  project_name  = "web-platform"

  # Multi-tenant tags (Customer + Project)
  # VPC will be discovered with tags: Customer=acme-corp, Project=web-platform

  # Cluster Configuration
  kubernetes_version = "1.31"
  architecture_type  = "dedicated_local"
  plan_tier         = "enterprise"

  # NAT Gateway
  enable_nat_gateway = true

  # Subnet configuration
  eks_subnet_az_count      = 3
  eks_subnet_newbits       = 3
  eks_subnet_netnum_start  = 4

  # System node group
  system_node_desired_size   = 4
  system_node_min_size       = 2
  system_node_max_size       = 12
  system_node_instance_types = ["m7g.xlarge"]

  tags = {
    Project    = "WebPlatform"
    CostCenter = "ACME-WEB"
  }
}
*/

# ------------------------------------------------------------------------------
# Example 4: Customer with Multiple Projects (Same Region)
# ------------------------------------------------------------------------------
# Use Case: Deploy multiple EKS clusters for different projects of same customer
# ------------------------------------------------------------------------------

/*
# Project: Web Platform
module "eks_acme_web" {
  source = "./eks"

  workspace         = "production"
  environment       = "production"
  aws_region        = "eu-west-1"
  
  customer_id       = "CUST001"
  customer_name     = "acme-corp"
  project_name      = "web-platform"
  
  kubernetes_version = "1.31"
  architecture_type  = "dedicated_local"
  
  enable_nat_gateway = true
}

# Project: Mobile Backend
module "eks_acme_mobile" {
  source = "./eks"

  workspace         = "production"
  environment       = "production"
  aws_region        = "eu-west-1"
  
  customer_id       = "CUST001"
  customer_name     = "acme-corp"
  project_name      = "mobile-backend"
  
  kubernetes_version = "1.31"
  architecture_type  = "dedicated_local"
  
  enable_nat_gateway = true
}

# Project: Data Platform
module "eks_acme_data" {
  source = "./eks"

  workspace         = "production"
  environment       = "production"
  aws_region        = "eu-west-1"
  
  customer_id       = "CUST001"
  customer_name     = "acme-corp"
  project_name      = "data-platform"
  
  kubernetes_version = "1.31"
  architecture_type  = "dedicated_local"
  
  enable_nat_gateway = true
}
*/

# ==============================================================================
# Multi-Tenant Tagging Strategy
# ==============================================================================
# All resources will include these tags for discovery and cost allocation:
#
# Base Tags (always present):
#   - ManagedBy = "Terraform"
#   - Environment = "production"
#   - Region = "eu-west-1"
#
# Multi-Tenant Tags:
#   - Customer = "acme-corp" (if customer_name is set)
#   - Project = "web-platform" (if project_name is set)
#
# Legacy Tags (for backward compatibility):
#   - CustomerId = "CUST001"
#   - CustomerName = "acme-corp"
#
# Naming Conventions:
#   - Shared: forge-{environment}-eks
#   - Customer: {customer_name}-{region}-eks
#   - Project: {customer_name}-{project_name}-{region}-eks
# ==============================================================================
