output "sync_executed" {
  description = "Indicates whether sync was executed"
  value       = var.sync_mode != "none"
}

output "sync_mode" {
  description = "Sync mode used (upload/download/none)"
  value       = var.sync_mode
}

output "yaml_file_path" {
  description = "Path to local YAML file"
  value       = var.yaml_file_path
}

output "ssm_parameter_name" {
  description = "SSM Parameter Store path"
  value       = var.ssm_parameter_name
}

output "yaml_file_hash" {
  description = "SHA256 hash of YAML file content (for change detection)"
  value       = local.yaml_file_hash
}

output "docker_command" {
  description = "Docker command executed for sync"
  value       = var.sync_mode != "none" ? local.docker_command : null
}

output "module_tags" {
  description = "Tags applied by this module"
  value       = local.all_tags
}
