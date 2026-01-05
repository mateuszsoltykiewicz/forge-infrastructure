# ==============================================================================
# EKS Module - Input Variables
# ==============================================================================
# This module creates an Amazon EKS cluster with managed node groups.
# It supports customer-aware naming and tagging for multi-tenant environments.
# ==============================================================================

# ------------------------------------------------------------------------------
# Customer Context (Required for Customer-Aware Naming)
# ------------------------------------------------------------------------------

variable "customer_id" {
  description = "Customer identifier (empty for shared infrastructure)"
  type        = string
  default     = ""
}

variable "customer_name" {
  description = "Customer name for resource naming (empty for shared infrastructure)"
  type        = string
  default     = ""
}

variable "architecture_type" {
  description = "Architecture deployment type: shared, dedicated_local, or dedicated_regional"
  type        = string
  default     = "shared"

  validation {
    condition     = contains(["shared", "dedicated_local", "dedicated_regional"], var.architecture_type)
    error_message = "Architecture type must be one of: shared, dedicated_local, or dedicated_regional."
  }
}

variable "plan_tier" {
  description = "Customer plan tier (e.g., basic, pro, advanced) for cost allocation"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# EKS Cluster Configuration
# ------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be one of: production, staging, or development."
  }
}

variable "aws_region" {
  description = "AWS region where the EKS cluster will be deployed"
  type        = string
}

variable "cluster_name_override" {
  description = "Optional override for cluster name (if empty, auto-generated based on customer context)"
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"

  validation {
    condition     = can(regex("^1\\.(2[89]|3[0-9])$", var.kubernetes_version))
    error_message = "Kubernetes version must be 1.28 or higher."
  }
}

# ------------------------------------------------------------------------------
# Network Configuration
# ------------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "control_plane_subnet_ids" {
  description = "Subnet IDs for the EKS control plane (must span at least 2 AZs)"
  type        = list(string)

  validation {
    condition     = length(var.control_plane_subnet_ids) >= 2
    error_message = "Control plane must span at least 2 availability zones."
  }
}

variable "node_group_subnet_ids" {
  description = "Subnet IDs for EKS worker nodes (private subnets recommended)"
  type        = list(string)

  validation {
    condition     = length(var.node_group_subnet_ids) >= 2
    error_message = "Node groups must span at least 2 availability zones."
  }
}

# ------------------------------------------------------------------------------
# Cluster Endpoint Configuration
# ------------------------------------------------------------------------------

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ------------------------------------------------------------------------------
# Cluster Logging Configuration
# ------------------------------------------------------------------------------

variable "enabled_cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  description = "Number of days to retain cluster logs in CloudWatch"
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cluster_log_retention_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention period."
  }
}

# ------------------------------------------------------------------------------
# EKS Add-ons Configuration
# ------------------------------------------------------------------------------

variable "enable_ebs_csi_driver" {
  description = "Enable AWS EBS CSI driver add-on for persistent volumes"
  type        = bool
  default     = true
}

variable "enable_vpc_cni" {
  description = "Enable VPC CNI add-on for pod networking"
  type        = bool
  default     = true
}

variable "enable_kube_proxy" {
  description = "Enable kube-proxy add-on"
  type        = bool
  default     = true
}

variable "enable_coredns" {
  description = "Enable CoreDNS add-on for DNS resolution"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# Managed Node Groups Configuration
# ------------------------------------------------------------------------------

variable "node_groups" {
  description = "Map of EKS managed node groups to create"
  type = map(object({
    desired_size   = number
    min_size       = number
    max_size       = number
    instance_types = list(string)
    capacity_type  = string # ON_DEMAND or SPOT
    disk_size      = number
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {
    system = {
      desired_size   = 2
      min_size       = 2
      max_size       = 4
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      labels = {
        role = "system"
      }
      taints = []
    }
    application = {
      desired_size   = 3
      min_size       = 2
      max_size       = 10
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 100
      labels = {
        role = "application"
      }
      taints = []
    }
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : contains(["ON_DEMAND", "SPOT"], v.capacity_type)])
    error_message = "Node group capacity_type must be either ON_DEMAND or SPOT."
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : v.min_size <= v.desired_size && v.desired_size <= v.max_size])
    error_message = "Node group sizes must satisfy: min_size <= desired_size <= max_size."
  }
}

# ------------------------------------------------------------------------------
# Customer-Specific Node Groups (for Shared Architecture)
# ------------------------------------------------------------------------------

variable "customer_node_groups" {
  description = <<-EOT
    Map of customer-specific node groups for shared architecture (Basic plan customers).
    Each customer gets a dedicated node group with taints to prevent cross-customer scheduling.
    Trial plan customers do NOT get dedicated node groups - they share the 'system' node group.
    
    Key = customer name (lowercase, hyphenated)
    Value = node group configuration
    
    Example:
      customer_node_groups = {
        "globex-corp" = {
          customer_id    = "cust_001"
          customer_name  = "globex-corp"
          plan_tier      = "basic"
          desired_size   = 1
          min_size       = 1
          max_size       = 3
          instance_types = ["t3.medium", "t3.large"]
          capacity_type  = "SPOT"
          disk_size      = 50
        }
      }
  EOT
  type = map(object({
    customer_id    = string
    customer_name  = string
    plan_tier      = string
    desired_size   = number
    min_size       = number
    max_size       = number
    instance_types = list(string)
    capacity_type  = string # ON_DEMAND or SPOT
    disk_size      = number
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.customer_node_groups : contains(["ON_DEMAND", "SPOT"], v.capacity_type)])
    error_message = "Customer node group capacity_type must be either ON_DEMAND or SPOT."
  }

  validation {
    condition     = alltrue([for k, v in var.customer_node_groups : v.min_size <= v.desired_size && v.desired_size <= v.max_size])
    error_message = "Customer node group sizes must satisfy: min_size <= desired_size <= max_size."
  }

  validation {
    condition     = alltrue([for k, v in var.customer_node_groups : contains(["basic", "trial"], v.plan_tier)])
    error_message = "Customer node groups are only for 'basic' plan. Trial customers share the system node group."
  }
}

# ------------------------------------------------------------------------------
# Security Configuration
# ------------------------------------------------------------------------------

variable "security_group_ids" {
  description = "Additional security group IDs to attach to the cluster"
  type        = list(string)
  default     = []
}

variable "node_security_group_ids" {
  description = "Additional security group IDs to attach to worker nodes"
  type        = list(string)
  default     = []
}

# ------------------------------------------------------------------------------
# IAM Configuration
# ------------------------------------------------------------------------------

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts (IRSA)"
  type        = bool
  default     = true
}

variable "cluster_creator_admin_permissions" {
  description = "Enable cluster creator admin permissions"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# Resource Tags
# ------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all EKS resources"
  type        = map(string)
  default     = {}
}
