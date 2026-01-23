locals {
  module_name = "security-group-chainer"

  module_tags = {
    TerraformModule = "forge/aws/security/security-group-chainer"
    Module          = local.module_name
    Type            = "automation"
  }

  all_tags = merge(
    var.common_tags,
    local.module_tags
  )

  # Determine config source (SSM preferred, YAML fallback)
  use_ssm_config  = var.chains_config_ssm_parameter != ""
  use_yaml_config = var.chains_config_yaml_path != "" && !local.use_ssm_config

  # Docker command arguments
  chainer_args = concat(
    ["run"],
    local.use_ssm_config ? ["--ssm-parameter", var.chains_config_ssm_parameter] : [],
    local.use_yaml_config ? ["--config", var.chains_config_yaml_path] : [],
    ["--region", var.aws_region],
    ["--timeout", tostring(var.timeout_seconds)],
    ["--output", var.report_output_path]
  )

  # Docker command for async polling mode - mount AWS credentials for non-root user
  docker_command_async = <<-EOT
    docker run --rm \
      -v "$${HOME}/.aws:/home/chainer/.aws:ro" \
      -v "${abspath(path.root)}:/workspace" \
      -e AWS_REGION=${var.aws_region} \
      -e VPC_ID=${var.vpc_id != null ? var.vpc_id : ""} \
      -e POLLING_ENABLED=${var.polling_enabled} \
      -e ASYNC_PROCESSING=${var.async_processing} \
      -e REQUIRED_SG_TAGS='${jsonencode(var.required_sg_tags)}' \
      -e POLLING_INTERVAL_SECONDS=${coalesce(var.polling_interval_seconds, 15)} \
      -e MAX_POLLING_DURATION=${coalesce(var.max_polling_duration_seconds, 7200)} \
      -e MAX_PARALLEL_CHAINS=${var.max_parallel_chains} \
      ${var.docker_image} \
      ${local.use_ssm_config ? "--ssm-parameter ${var.chains_config_ssm_parameter}" : "--yaml-config ${var.chains_config_yaml_path}"} \
      --output ${var.report_output_path}
  EOT

  # Full Docker command (fallback to async)
  docker_command = local.docker_command_async
}
