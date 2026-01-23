output "chainer_executed" {
  description = "Indicates whether chainer was executed"
  value       = var.enabled
}

output "config_source" {
  description = "Configuration source (SSM parameter or YAML file)"
  value       = local.use_ssm_config ? "SSM: ${var.chains_config_ssm_parameter}" : (local.use_yaml_config ? "YAML: ${var.chains_config_yaml_path}" : "None")
}

output "report_path" {
  description = "Path to chainer execution report"
  value       = var.enabled ? var.report_output_path : null
}

output "docker_command" {
  description = "Docker command executed by chainer"
  value       = var.enabled ? local.docker_command : null
}

output "module_tags" {
  description = "Tags applied by this module"
  value       = local.all_tags
}
