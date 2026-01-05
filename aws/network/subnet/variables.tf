# ==============================================================================
# Subnet Module Variables (Forge - Customer-Centric)
# ==============================================================================

# ------------------------------------------------------------------------------
# Required Variables
# ------------------------------------------------------------------------------

variable "vpc_id" {
  type        = string
  description = "VPC ID where subnets will be created. Use output from VPC module."
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC (used for route table naming)."
}

variable "subnets" {
  type = list(object({
    name              = string # Unique name for the subnet (e.g., "eks-us-east-1a-public")
    cidr_block        = string # CIDR block (e.g., "10.0.1.0/24")
    availability_zone = string # AZ (e.g., "us-east-1a")
    tier              = string # "public" or "private"
    purpose           = string # Purpose tag (e.g., "eks", "database", "application")
  }))
  description = "List of subnet configurations. Each subnet requires name, CIDR, AZ, tier, and purpose."

  validation {
    condition     = length(var.subnets) > 0
    error_message = "At least one subnet must be configured."
  }

  validation {
    condition     = alltrue([for s in var.subnets : contains(["public", "private"], lower(s.tier))])
    error_message = "Subnet tier must be either 'public' or 'private'."
  }

  validation {
    condition     = alltrue([for s in var.subnets : can(cidrnetmask(s.cidr_block))])
    error_message = "All subnets must have valid CIDR block notation."
  }
}

# ------------------------------------------------------------------------------
# Forge Infrastructure Variables
# ------------------------------------------------------------------------------

variable "workspace" {
  type        = string
  description = "Terraform workspace name (e.g., 'production', 'staging', 'development')."
  validation {
    condition     = length(var.workspace) > 0
    error_message = "Workspace name cannot be empty."
  }
}

variable "environment" {
  type        = string
  description = "Environment identifier (e.g., 'prod', 'staging', 'dev')."
  validation {
    condition     = contains(["prod", "staging", "dev"], var.environment)
    error_message = "Environment must be one of: prod, staging, dev."
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region where subnets are created."
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "Invalid AWS region format. Expected format: us-east-1, eu-west-1, etc."
  }
}

# ------------------------------------------------------------------------------
# Customer Context Variables (Optional)
# ------------------------------------------------------------------------------

variable "customer_id" {
  type        = string
  description = "Customer UUID from Forge database. Required for dedicated architectures."
  default     = null
}

variable "customer_name" {
  type        = string
  description = "Customer name for resource naming. Required for dedicated architectures."
  default     = null
}

variable "architecture_type" {
  type        = string
  description = "Architecture deployment model: 'shared', 'dedicated_local', 'dedicated_regional'."
  default     = "shared"
  
  validation {
    condition     = contains(["shared", "dedicated_local", "dedicated_regional"], var.architecture_type)
    error_message = "Architecture type must be one of: shared, dedicated_local, dedicated_regional."
  }
}

variable "plan_tier" {
  type        = string
  description = "Customer plan tier (e.g., 'trial', 'basic', 'pro', 'enterprise')."
  default     = null
}

# ------------------------------------------------------------------------------
# Tagging Variables
# ------------------------------------------------------------------------------

variable "common_tags" {
  type        = map(string)
  description = "Additional tags to apply to all subnet resources."
  default     = {}
}

# ==============================================================================
# Forge Best Practices:
# ==============================================================================
# - Subnets list should include at least 2 AZs for high availability
# - Use consistent naming: {purpose}-{az}-{tier} (e.g., "eks-us-east-1a-private")
# - Public tier: Load balancers, NAT gateways, bastion hosts
# - Private tier: EKS nodes, RDS, ElastiCache, application servers
# - Purpose examples: eks, database, application, cache, transit
# ==============================================================================
