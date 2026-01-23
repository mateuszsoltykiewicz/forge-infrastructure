variable "common_prefix" {
  description = "Common prefix for resource naming"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
}

variable "sync_mode" {
  description = "Sync mode: 'upload' (YAML to SSM), 'download' (SSM to YAML), or 'none' (skip)"
  type        = string
  default     = "upload"

  validation {
    condition     = contains(["upload", "download", "none"], var.sync_mode)
    error_message = "sync_mode must be 'upload', 'download', or 'none'"
  }
}

variable "yaml_file_path" {
  description = "Path to local YAML file"
  type        = string
}

variable "ssm_parameter_name" {
  description = "SSM Parameter Store path (e.g., /forge/security-group-chains)"
  type        = string
}

variable "docker_image" {
  description = "Docker image for yaml-sync-with-ssm"
  type        = string
  default     = "yaml-ssm-sync:1.0.0"
}

variable "aws_region" {
  description = "AWS region for SSM operations"
  type        = string
}

variable "validate_before_upload" {
  description = "Validate YAML schema before uploading to SSM"
  type        = bool
  default     = true
}

variable "force_sync" {
  description = "Force sync even if content is identical"
  type        = bool
  default     = false
}

variable "parameter_description" {
  description = "Description for SSM parameter (used in upload mode)"
  type        = string
  default     = "Synchronized from Terraform"
}

variable "trigger_on_yaml_change" {
  description = "Trigger sync when YAML file content changes"
  type        = bool
  default     = true
}
