# ==============================================================================
# Resource Creation Control
# ==============================================================================

variable "create" {
  description = "Whether to create resources. Set to false to skip resource creation."
  type        = bool
  default     = true
}


# ==============================================================================
# ElastiCache Redis Module - Input Variables
# ==============================================================================
# This module creates an Amazon ElastiCache Redis cluster.
# Optimized for Forge's caching and session management requirements.
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
  description = "Project name within customer context (e.g., web-platform, mobile-app). Enables multiple Redis clusters per customer."
  type        = string
  default     = ""
}

variable "plan_tier" {
  description = "Customer plan tier (e.g., basic, pro, advanced) for cost allocation"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# ElastiCache Configuration
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
  description = "AWS region where the ElastiCache cluster will be deployed"
  type        = string
}

variable "workspace" {
  description = "Workspace identifier for VPC discovery (e.g., production, staging)"
  type        = string

  validation {
    condition     = length(var.workspace) > 0
    error_message = "Workspace must not be empty."
  }
}

variable "replication_group_id_override" {
  description = "Optional override for replication group ID (if empty, auto-generated)"
  type        = string
  default     = ""
}

variable "description" {
  description = "Description of the replication group"
  type        = string
  default     = "Forge Redis cluster for caching and session management"
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"

  validation {
    condition     = can(regex("^[67]\\.[0-9]+$", var.engine_version))
    error_message = "Redis version must be 6.x or 7.x."
  }
}

variable "node_type" {
  description = "ElastiCache node type (e.g., cache.r7g.large for production)"
  type        = string
  default     = "cache.r7g.large"
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (nodes) in the replication group"
  type        = number
  default     = 2

  validation {
    condition     = var.num_cache_clusters >= 1 && var.num_cache_clusters <= 6
    error_message = "Number of cache clusters must be between 1 and 6."
  }
}

variable "port" {
  description = "Redis port"
  type        = number
  default     = 6379

  validation {
    condition     = var.port >= 1024 && var.port <= 65535
    error_message = "Port must be between 1024 and 65535."
  }
}

# ------------------------------------------------------------------------------
# Network Configuration (Auto-Discovery)
# ------------------------------------------------------------------------------

# VPC and subnets are auto-discovered by tags
# No manual vpc_id or subnet_ids required!

variable "redis_subnet_az_count" {
  description = "Number of availability zones for Redis subnets (2-3)"
  type        = number
  default     = 3

  validation {
    condition     = var.redis_subnet_az_count >= 2 && var.redis_subnet_az_count <= 3
    error_message = "Redis subnets must span 2 or 3 availability zones."
  }
}

variable "redis_subnet_newbits" {
  description = "Number of additional bits to add to VPC CIDR for Redis subnets (e.g., 8 for /24 from /16 VPC)"
  type        = number
  default     = 8

  validation {
    condition     = var.redis_subnet_newbits >= 1 && var.redis_subnet_newbits <= 12
    error_message = "Subnet newbits must be between 1 and 12."
  }
}

variable "redis_subnet_netnum_start" {
  description = "Starting network number for Redis subnet CIDR calculation"
  type        = number
  default     = 100

  validation {
    condition     = var.redis_subnet_netnum_start >= 0
    error_message = "Subnet netnum_start must be non-negative."
  }
}

variable "eks_cluster_name" {
  description = "EKS cluster name for security group integration (optional, auto-discovered if empty)"
  type        = string
  default     = ""
}

variable "preferred_cache_cluster_azs" {
  description = "List of AZs in which the cache clusters will be created"
  type        = list(string)
  default     = []
}

# ------------------------------------------------------------------------------
# High Availability Configuration
# ------------------------------------------------------------------------------

variable "multi_az_enabled" {
  description = "Enable Multi-AZ with automatic failover"
  type        = bool
  default     = true
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover (required for Multi-AZ)"
  type        = bool
  default     = true

  validation {
    condition     = !var.automatic_failover_enabled || var.num_cache_clusters >= 2
    error_message = "Automatic failover requires at least 2 cache clusters."
  }
}

# ------------------------------------------------------------------------------
# Security Configuration
# ------------------------------------------------------------------------------

variable "at_rest_encryption_enabled" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "Enable encryption in transit (TLS)"
  type        = bool
  default     = true
}

variable "auth_token_enabled" {
  description = "Enable Redis AUTH token for authentication"
  type        = bool
  default     = true
}

variable "enable_kms_key_rotation" {
  description = "Enable automatic KMS key rotation"
  type        = bool
  default     = true
}

variable "kms_deletion_window_in_days" {
  description = "KMS key deletion window in days (7-30)"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

# ------------------------------------------------------------------------------
# Backup Configuration
# ------------------------------------------------------------------------------

variable "snapshot_retention_limit" {
  description = "Number of days to retain automatic snapshots (0-35)"
  type        = number
  default     = 7

  validation {
    condition     = var.snapshot_retention_limit >= 0 && var.snapshot_retention_limit <= 35
    error_message = "Snapshot retention limit must be between 0 and 35 days."
  }
}

variable "snapshot_window" {
  description = "Daily time range for snapshots (UTC, e.g., 03:00-05:00)"
  type        = string
  default     = "03:00-05:00"

  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]-([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.snapshot_window))
    error_message = "Snapshot window must be in format HH:MM-HH:MM (UTC)."
  }
}

variable "final_snapshot_identifier" {
  description = "Name of final snapshot on deletion (if empty, no final snapshot)"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# Maintenance Configuration
# ------------------------------------------------------------------------------

variable "maintenance_window" {
  description = "Weekly maintenance window (UTC, e.g., sun:05:00-sun:07:00)"
  type        = string
  default     = "sun:05:00-sun:07:00"
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately (if false, apply during maintenance window)"
  type        = bool
  default     = true
}

variable "cloudwatch_retention_days" {
  description = "CloudWatch Logs retention period in days (1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653)"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_retention_days)
    error_message = "CloudWatch retention must be a valid value: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, or 3653 days."
  }
}

# ------------------------------------------------------------------------------
# Parameter Group Configuration
# ------------------------------------------------------------------------------

variable "create_parameter_group" {
  description = "Create a custom parameter group (if false, uses default)"
  type        = bool
  default     = true
}

variable "parameter_group_family" {
  description = "Redis parameter group family (e.g., redis7)"
  type        = string
  default     = "redis7"
}

variable "parameters" {
  description = "Redis parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "maxmemory-policy"
      value = "allkeys-lru"
    },
    {
      name  = "timeout"
      value = "300"
    }
  ]
}

# ------------------------------------------------------------------------------
# Monitoring Configuration
# ------------------------------------------------------------------------------

variable "notification_topic_arn" {
  description = "SNS topic ARN for ElastiCache notifications"
  type        = string
  default     = ""
}

variable "log_delivery_configuration" {
  description = "CloudWatch Logs delivery configuration"
  type = list(object({
    destination      = string
    destination_type = string
    log_format       = string
    log_type         = string
  }))
  default = []
}

# ------------------------------------------------------------------------------
# Resource Tags
# ------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all ElastiCache resources"
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------------------
# Resource Sharing Configuration
# ------------------------------------------------------------------------------

variable "resource_sharing" {
  description = "Resource sharing mode: 'dedicated' (single environment) or 'shared' (multiple environments)"
  type        = string
  default     = "dedicated"

  validation {
    condition     = contains(["dedicated", "shared"], var.resource_sharing)
    error_message = "Resource sharing must be 'dedicated' or 'shared'."
  }
}

variable "shared_with_environments" {
  description = "List of environments sharing this Redis cluster (when resource_sharing = 'shared'). Example: ['staging', 'development']"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for env in var.shared_with_environments :
      contains(["production", "staging", "development"], env)
    ])
    error_message = "Shared environments must be one of: production, staging, development."
  }
}
