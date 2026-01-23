
# ==============================================================================
# EKS Module - Input Variables
# ==============================================================================
# This module creates an Amazon EKS cluster using the official
# terraform-aws-modules/eks/aws module.
# ==============================================================================

variable "common_prefix" {
  description = "Common prefix for resource naming"
  type        = string
}

# ------------------------------------------------------------------------------
# Firewall / Communication Tier
# ------------------------------------------------------------------------------
variable "firewall_tier" {
  description = "Communication tier for resource naming and organization"
  type        = string
  default     = "EKS"
}

variable "firewall_type" {
  description = "Firewall type for resource naming and organization"
  type        = string
  default     = "Master"
}

# ------------------------------------------------------------------------------
# EKS Subnets Configuration
# ------------------------------------------------------------------------------

variable "kubernetes_cluster_tag_value" {
  description = "Value for kubernetes.io/cluster tag (owned or shared)"
  type        = string
  default     = "shared"

  validation {
    condition     = contains(["owned", "shared"], var.kubernetes_cluster_tag_value)
    error_message = "Cluster tag value must be 'owned' or 'shared'."
  }
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

variable "system_node_group_min_size" {
  description = "Minimum number of nodes in system node group"
  type        = number
  default     = 2

  validation {
    condition     = var.system_node_group_min_size >= 0
    error_message = "Minimum size must be at least 0 for high availability."
  }
}

variable "system_node_group_max_size" {
  description = "Maximum number of nodes in system node group"
  type        = number
  default     = 4

  validation {
    condition     = var.system_node_group_max_size >= var.system_node_group_min_size
    error_message = "Maximum size must be greater than or equal to minimum size."
  }
}

variable "system_node_group_desired_size" {
  description = "Desired number of nodes in system node group"
  type        = number
  default     = 2

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
    condition     = contains(["gp3", "io1", "io2"], var.system_node_group_disk_type)
    error_message = "Disk type must be one of: gp3, io1, io2."
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

variable "common_tags" {
  description = "Common tags passed from root module (ManagedBy, Workspace, Region, DomainName, Customer, Project)"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region for EKS cluster resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to deploy EKS within"
  type        = string
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

# ------------------------------------------------------------------------------
# Subnet Configuration
# ------------------------------------------------------------------------------

variable "subnet_cidrs" {
  description = "List of CIDR blocks for Client VPN subnets (from root locals)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_cidrs) > 0 && length(var.subnet_cidrs) <= 3
    error_message = "subnet_cidrs must contain 1-3 CIDR blocks"
  }
}

variable "availability_zones" {
  description = "List of availability zones for Client VPN subnets (from root locals)"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) > 0 && length(var.availability_zones) <= 3
    error_message = "availability_zones must contain 1-3 zones"
  }

  validation {
    condition     = length(var.availability_zones) == length(var.subnet_cidrs)
    error_message = "availability_zones and subnet_cidrs must have the same length"
  }
}

# ------------------------------------------------------------------------------
# Routing Configuration
# ------------------------------------------------------------------------------

variable "nat_gateway_ids" {
  description = "List of NAT Gateway IDs for private subnet egress (0.0.0.0/0 → NAT GW)"
  type        = list(string)
}

variable "s3_gateway_endpoint_id" {
  description = "S3 Gateway VPC Endpoint ID for route table association (ECR image pulls)"
  type        = string
  default     = null
}
