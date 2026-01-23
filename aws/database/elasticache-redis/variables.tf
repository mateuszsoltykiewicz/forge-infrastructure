# ==============================================================================
# ElastiCache Redis Module - Input Variables
# ==============================================================================
# This module creates an Amazon ElastiCache Redis cluster.
# Optimized for Forge's caching and session management requirements.
# ==============================================================================

variable "description" {
  description = "Description of the replication group"
  type        = string
  default     = "Forge Redis cluster for caching and session management"
}

# ------------------------------------------------------------------------------
# ElastiCache Configuration
# ------------------------------------------------------------------------------

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
# Security Configuration
# ------------------------------------------------------------------------------

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

  validation {
    condition     = can(regex("^(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]-(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]$", var.maintenance_window))
    error_message = "Maintenance window must be in format ddd:HH:MM-ddd:HH:MM (e.g., sun:05:00-sun:07:00)."
  }
}

# ------------------------------------------------------------------------------
# Monitoring Configuration
# ------------------------------------------------------------------------------

variable "cloudwatch_retention_days" {
  description = "CloudWatch Logs retention period in days (1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653)"
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_retention_days)
    error_message = "CloudWatch retention must be a valid value: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, or 3653 days."
  }
}

# ------------------------------------------------------------------------------
# Parameter Group Configuration
# ------------------------------------------------------------------------------

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

variable "common_tags" {
  description = "Common tags passed from root module (ManagedBy, Workspace, Region, DomainName, Customer, Project)"
  type        = map(string)
  default     = {}
}

variable "common_prefix" {
  description = "Common prefix for resource naming (e.g., forge-{environment}-{customer}-{project})"
  type        = string
}

# ------------------------------------------------------------------------------
# NEtwork COnfiguration
# ------------------------------------------------------------------------------
variable "vpc_id" {
  description = "VPC ID where the ElastiCache cluster will be deployed"
  type        = string
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