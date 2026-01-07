# ==============================================================================
# Resource Creation Control
# ==============================================================================

variable "create" {
  description = "Whether to create resources. Set to false to skip resource creation."
  type        = bool
  default     = true
}


# ==============================================================================
# EKS Module - Input Variables
# ==============================================================================
# This module creates an Amazon EKS cluster using the official
# terraform-aws-modules/eks/aws module.
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

variable "project_name" {
  description = "Project name within customer context (e.g., web-platform, mobile-app). Enables multiple EKS clusters per customer."
  type        = string
  default     = ""
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
  description = "Environment name (e.g., production, staging, development, shared)"
  type        = string

  validation {
    condition     = contains(["production", "staging", "development", "shared"], var.environment)
    error_message = "Environment must be one of: production, staging, development, or shared."
  }
}

variable "cluster_name_override" {
  description = "Optional override for cluster name (if empty, auto-generated based on customer context)"
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.30"

  validation {
    condition     = can(regex("^1\\.(2[89]|3[0-9])$", var.kubernetes_version))
    error_message = "Kubernetes version must be 1.28 or higher."
  }
}

# ------------------------------------------------------------------------------
# Network Configuration (Auto-Discovery)
# ------------------------------------------------------------------------------

variable "workspace" {
  description = "Workspace identifier for VPC discovery (e.g., production, staging)"
  type        = string

  validation {
    condition     = length(var.workspace) > 0
    error_message = "Workspace must not be empty."
  }
}

# ------------------------------------------------------------------------------
# EKS Subnets Configuration
# ------------------------------------------------------------------------------

variable "eks_subnet_az_count" {
  description = "Number of availability zones for EKS subnets (2-3)"
  type        = number
  default     = 3

  validation {
    condition     = var.eks_subnet_az_count >= 2 && var.eks_subnet_az_count <= 3
    error_message = "EKS subnets must span 2 or 3 availability zones."
  }
}

variable "eks_subnet_newbits" {
  description = "Number of additional bits to add to VPC CIDR for EKS subnets (e.g., 3 for /19 from /16 VPC)"
  type        = number
  default     = 3

  validation {
    condition     = var.eks_subnet_newbits >= 1 && var.eks_subnet_newbits <= 8
    error_message = "Subnet newbits must be between 1 and 8."
  }
}

variable "eks_subnet_netnum_start" {
  description = "Starting network number for EKS subnet CIDR calculation"
  type        = number
  default     = 4

  validation {
    condition     = var.eks_subnet_netnum_start >= 0
    error_message = "Subnet netnum_start must be non-negative."
  }
}

variable "kubernetes_cluster_tag_value" {
  description = "Value for kubernetes.io/cluster tag (owned or shared)"
  type        = string
  default     = "owned"

  validation {
    condition     = contains(["owned", "shared"], var.kubernetes_cluster_tag_value)
    error_message = "Cluster tag value must be 'owned' or 'shared'."
  }
}

variable "enable_ipv6" {
  description = "Enable IPv6 for EKS subnets"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for temporary public access (can be disabled after setup)"
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# Cluster Endpoint Configuration
# ------------------------------------------------------------------------------

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ------------------------------------------------------------------------------
# KMS Configuration
# ------------------------------------------------------------------------------

variable "kms_deletion_window_in_days" {
  description = "Number of days before KMS key deletion (7-30)"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

variable "enable_kms_key_rotation" {
  description = "Enable automatic KMS key rotation"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# CloudWatch Logging Configuration
# ------------------------------------------------------------------------------

variable "cluster_enabled_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  validation {
    condition = alltrue([
      for log_type in var.cluster_enabled_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "Valid log types are: api, audit, authenticator, controllerManager, scheduler."
  }
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain cluster logs in CloudWatch"
  type        = number
  default     = 90

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_group_retention_in_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention period."
  }
}

# ------------------------------------------------------------------------------
# System Node Group Configuration
# ------------------------------------------------------------------------------

variable "system_node_group_instance_types" {
  description = "Instance types for system node group (Graviton3 recommended)"
  type        = list(string)
  default     = ["m7g.large", "m7g.xlarge"]
}

variable "system_node_group_capacity_type" {
  description = "Capacity type for system node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.system_node_group_capacity_type)
    error_message = "Capacity type must be either ON_DEMAND or SPOT."
  }
}

variable "system_node_group_min_size" {
  description = "Minimum number of nodes in system node group"
  type        = number
  default     = 2

  validation {
    condition     = var.system_node_group_min_size >= 2
    error_message = "Minimum size must be at least 2 for high availability."
  }
}

variable "system_node_group_max_size" {
  description = "Maximum number of nodes in system node group"
  type        = number
  default     = 10

  validation {
    condition     = var.system_node_group_max_size >= var.system_node_group_min_size
    error_message = "Maximum size must be greater than or equal to minimum size."
  }
}

variable "system_node_group_desired_size" {
  description = "Desired number of nodes in system node group"
  type        = number
  default     = 3

  validation {
    condition     = var.system_node_group_desired_size >= var.system_node_group_min_size && var.system_node_group_desired_size <= var.system_node_group_max_size
    error_message = "Desired size must be between min and max size."
  }
}

variable "system_node_group_disk_size" {
  description = "Disk size in GB for system node group"
  type        = number
  default     = 100

  validation {
    condition     = var.system_node_group_disk_size >= 20
    error_message = "Disk size must be at least 20 GB."
  }
}

variable "system_node_group_disk_type" {
  description = "Disk type for system node group (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.system_node_group_disk_type)
    error_message = "Disk type must be one of: gp2, gp3, io1, io2."
  }
}

variable "system_node_group_disk_iops" {
  description = "IOPS for system node group disk (only for gp3, io1, io2)"
  type        = number
  default     = 3000

  validation {
    condition     = var.system_node_group_disk_iops >= 3000 && var.system_node_group_disk_iops <= 16000
    error_message = "Disk IOPS must be between 3000 and 16000 for gp3/io1/io2 volumes."
  }
}

variable "system_node_group_disk_throughput" {
  description = "Throughput in MB/s for system node group disk (only for gp3)"
  type        = number
  default     = 150

  validation {
    condition     = var.system_node_group_disk_throughput >= 125 && var.system_node_group_disk_throughput <= 1000
    error_message = "Disk throughput must be between 125 and 1000 MB/s for gp3 volumes."
  }
}

variable "enable_system_node_taints" {
  description = "Enable taints on system nodes (CriticalAddonsOnly)"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# Bootstrap Configuration
# ------------------------------------------------------------------------------

variable "enable_bootstrap_user_data" {
  description = "Enable custom bootstrap user data for nodes"
  type        = bool
  default     = false
}

variable "pre_bootstrap_user_data" {
  description = "Custom user data to run before node bootstrap"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# IAM Configuration
# ------------------------------------------------------------------------------

variable "enable_cluster_autoscaler_iam" {
  description = "Create IAM role for Cluster Autoscaler"
  type        = bool
  default     = true
}

variable "enable_ebs_csi_kms_policy" {
  description = "Attach additional KMS policy to EBS CSI driver role for encrypted volumes"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# Access Management
# ------------------------------------------------------------------------------

variable "additional_access_entries" {
  description = "Additional IAM principals to grant cluster access (merged with terraform caller)"
  type        = any
  default     = {}
}

# ------------------------------------------------------------------------------
# Resource Tags
# ------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all EKS resources"
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------------------
# Kubernetes Namespaces Configuration
# ------------------------------------------------------------------------------

variable "namespaces" {
  description = <<-EOD
    Map of Kubernetes namespaces to create with resource quotas and network policies.
    Each namespace can have:
    - labels: Custom labels for the namespace
    - resource_quota: CPU, memory, and pod limits
    - network_policy: Ingress/egress rules
    
    Example:
    {
      "prod-cronus" = {
        labels = { team = "cronus", tier = "production" }
        resource_quota = {
          hard = {
            "requests.cpu"    = "10"
            "requests.memory" = "20Gi"
            "pods"            = "50"
          }
        }
        network_policy = {
          ingress_from_namespaces = ["dev-cronus", "stag-cronus"]
          egress_allowed          = true
        }
      }
    }
  EOD
  type = map(object({
    labels = optional(map(string), {})
    resource_quota = optional(object({
      hard = optional(map(string), {})
    }), null)
    network_policy = optional(object({
      ingress_from_namespaces = optional(list(string), [])
      egress_allowed          = optional(bool, true)
    }), null)
  }))
  default = {}
}
