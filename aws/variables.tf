# ==============================================================================
# Root Module - Input Variables
# ==============================================================================
# This file defines variables for multi-environment infrastructure deployment.
# ==============================================================================

# ------------------------------------------------------------------------------
# Workspace Configuration
# ------------------------------------------------------------------------------

variable "workspace" {
  description = "Workspace identifier for all resources (e.g., 'forge-platform')"
  type        = string
  default     = "forge-platform"

  validation {
    condition     = length(var.workspace) > 0
    error_message = "Workspace must not be empty."
  }
}

# ------------------------------------------------------------------------------
# Environment Flags (Enable/Disable Environments)
# ------------------------------------------------------------------------------

variable "enable_production" {
  description = "Enable production environment deployment"
  type        = bool
  default     = true
}

variable "enable_staging" {
  description = "Enable staging environment deployment"
  type        = bool
  default     = true
}

variable "enable_development" {
  description = "Enable development environment deployment"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# Customer Context (Optional - for customer-specific deployments)
# ------------------------------------------------------------------------------

variable "customer_name" {
  description = "Customer name for resource naming (null for shared infrastructure)"
  type        = string
  default     = null
}

variable "project_name" {
  description = "Project name for resource naming (null for customer or shared infrastructure)"
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# VPC Configuration
# ------------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g., 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

# ------------------------------------------------------------------------------
# Domain Configuration
# ------------------------------------------------------------------------------

variable "domain_name" {
  description = "Base domain name for the infrastructure (e.g., 'insighthealth.io')"
  type        = string
  default     = "insighthealth.io"
}

# ------------------------------------------------------------------------------
# Resource Sharing Configuration
# ------------------------------------------------------------------------------

variable "shared_database_environments" {
  description = "List of environments sharing the production database (e.g., ['staging', 'development'])"
  type        = list(string)
  default     = ["staging", "development"]

  validation {
    condition = alltrue([
      for env in var.shared_database_environments :
      contains(["staging", "development"], env)
    ])
    error_message = "Only staging and development can share databases with production."
  }
}

variable "shared_redis_environments" {
  description = "List of environments sharing the production Redis cluster (e.g., ['staging', 'development'])"
  type        = list(string)
  default     = ["staging", "development"]

  validation {
    condition = alltrue([
      for env in var.shared_redis_environments :
      contains(["staging", "development"], env)
    ])
    error_message = "Only staging and development can share Redis with production."
  }
}

# ------------------------------------------------------------------------------
# EKS Configuration
# ------------------------------------------------------------------------------

variable "eks_kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "eks_node_instance_types" {
  description = "Instance types for EKS managed node groups"
  type        = list(string)
  default     = ["t3.large"]
}

variable "eks_node_desired_size" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 3
}

variable "eks_node_min_size" {
  description = "Minimum number of nodes in the EKS node group"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Maximum number of nodes in the EKS node group"
  type        = number
  default     = 6
}

# ------------------------------------------------------------------------------
# RDS Configuration
# ------------------------------------------------------------------------------

variable "rds_instance_class" {
  description = "RDS instance type for production (e.g., 'db.r8g.xlarge')"
  type        = string
  default     = "db.r8g.xlarge"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB for production RDS"
  type        = number
  default     = 500
}

# ------------------------------------------------------------------------------
# Redis Configuration
# ------------------------------------------------------------------------------

variable "redis_node_type" {
  description = "ElastiCache Redis node type for production (e.g., 'cache.r7g.large')"
  type        = string
  default     = "cache.r7g.large"
}

variable "redis_num_cache_nodes" {
  description = "Number of cache nodes for production Redis"
  type        = number
  default     = 2
}

# ------------------------------------------------------------------------------
# ALB Configuration
# ------------------------------------------------------------------------------

variable "alb_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listeners (wildcard *.insighthealth.io)"
  type        = string
  default     = null  # Must be created manually or via separate ACM module
}

# ------------------------------------------------------------------------------
# NodePort Configuration (EKS Service Ports)
# ------------------------------------------------------------------------------

variable "nodeport_production" {
  description = "NodePort for production environment service"
  type        = number
  default     = 30082

  validation {
    condition     = var.nodeport_production >= 30000 && var.nodeport_production <= 32767
    error_message = "NodePort must be in range 30000-32767."
  }
}

variable "nodeport_staging" {
  description = "NodePort for staging environment service"
  type        = number
  default     = 30081

  validation {
    condition     = var.nodeport_staging >= 30000 && var.nodeport_staging <= 32767
    error_message = "NodePort must be in range 30000-32767."
  }
}

variable "nodeport_development" {
  description = "NodePort for development environment service"
  type        = number
  default     = 30080

  validation {
    condition     = var.nodeport_development >= 30000 && var.nodeport_development <= 32767
    error_message = "NodePort must be in range 30000-32767."
  }
}

# ------------------------------------------------------------------------------
# Tags
# ------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------------------
# VPC Endpoints Configuration (Future Private Deployment)
# ------------------------------------------------------------------------------

variable "enable_vpc_endpoints" {
  description = "Enable VPC Endpoints for private AWS service access (default: false)"
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# VPN Configuration (Future Private Deployment)
# ------------------------------------------------------------------------------

variable "enable_vpn" {
  description = "Enable AWS Client VPN Endpoint for private access (default: false)"
  type        = bool
  default     = false
}

variable "vpn_client_cidr" {
  description = "CIDR block for VPN clients (e.g., '172.16.0.0/22')"
  type        = string
  default     = "172.16.0.0/22"

  validation {
    condition     = can(cidrnetmask(var.vpn_client_cidr))
    error_message = "VPN client CIDR must be a valid CIDR block."
  }
}

variable "vpn_dns_servers" {
  description = "List of DNS servers for VPN clients (defaults to VPC DNS)"
  type        = list(string)
  default     = []
}

# ------------------------------------------------------------------------------
# EKS Endpoint Access Configuration
# ------------------------------------------------------------------------------

variable "eks_endpoint_public_access" {
  description = "Enable public access to EKS API endpoint (default: true, set false when VPN enabled)"
  type        = bool
  default     = true
}

variable "eks_endpoint_private_access" {
  description = "Enable private access to EKS API endpoint (default: true)"
  type        = bool
  default     = true
}

variable "eks_public_access_cidrs" {
  description = "CIDR blocks allowed to access EKS public endpoint (default: ['0.0.0.0/0'])"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ------------------------------------------------------------------------------
# AWS Region (for VPC Endpoints)
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for deployment (e.g., 'us-east-1')"
  type        = string
  default     = "us-east-1"
}

