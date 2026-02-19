variable "common_prefix" {
  description = "Common prefix for resource naming"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
}

variable "chains_config_ssm_parameter" {
  description = "SSM Parameter Store path for chains configuration (e.g., /forge/security-group-chains)"
  type        = string
  default     = "/forge/security-group-chains"
}

variable "chains_config_yaml_path" {
  description = "Local path to chains configuration YAML file (fallback if SSM not available)"
  type        = string
  default     = ""
}

variable "docker_image" {
  description = "Docker image for security-group-chainer"
  type        = string
  default     = "security-group-chainer:latest"
}

variable "aws_region" {
  description = "AWS region for chainer operations"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for security group filtering (optional but recommended)"
  type        = string
  default     = null

  validation {
    condition     = var.vpc_id == null || can(regex("^vpc-[a-z0-9]{8,}$", var.vpc_id))
    error_message = "vpc_id must be null or a valid VPC ID format (vpc-xxxxxxxx)"
  }
}

variable "timeout_seconds" {
  description = "Timeout for chainer execution (seconds)"
  type        = number
  default     = 1800
}

variable "enabled" {
  description = "Enable or disable security group chainer execution"
  type        = bool
  default     = true
}

variable "depends_on_resources" {
  description = "DEPRECATED: Not used in async polling mode. Kept for backward compatibility."
  type        = list(string)
  default     = []
}

# ==============================================================================
# Asynchroniczny Polling Mode
# ==============================================================================

variable "polling_enabled" {
  description = "Enable async polling: independently check AWS for each SG from chains.yaml"
  type        = bool
  default     = true
}

variable "polling_interval_seconds" {
  description = "Seconds between polling attempts (overrides chains.yaml if set)"
  type        = number
  default     = null # Use value from chains.yaml
}

variable "max_polling_duration_seconds" {
  description = "Maximum polling duration in seconds (overrides chains.yaml if set)"
  type        = number
  default     = null # Use value from chains.yaml (7200s = 2h)
}

# ==============================================================================
# Filtrowanie Security Groups
# ==============================================================================

variable "required_sg_tags" {
  description = <<-EOT
    Tags to filter security groups. All non-empty tags must match.
    Recommended: Pass local.merged_tags from root module for consistency.
    
    Example:
    {
      ManagedBy   = "Terraform"
      Region      = "us-east-1"
      Customer    = "customer"
      Project     = "project"
      Environment = "shared"
    }
  EOT
  type        = map(string)
  default     = {}
}

# ==============================================================================
# Asynchroniczne Przetwarzanie
# ==============================================================================

variable "async_processing" {
  description = "Process each security group chain independently (parallel execution)"
  type        = bool
  default     = true
}

variable "max_parallel_chains" {
  description = "Maximum number of chains to process in parallel (0 = unlimited)"
  type        = number
  default     = 5

  validation {
    condition     = var.max_parallel_chains >= 0
    error_message = "max_parallel_chains must be >= 0 (0 means unlimited)."
  }
}

variable "report_output_path" {
  description = "Path where chainer will save the execution report"
  type        = string
  default     = "./security-group-chainer-report.yaml"
}
