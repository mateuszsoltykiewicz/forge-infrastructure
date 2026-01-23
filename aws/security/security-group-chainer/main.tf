terraform {
  required_version = ">= 1.6"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Null resource to execute security-group-chainer (ASYNC POLLING MODE)
resource "null_resource" "security_group_chainer" {
  count = var.enabled ? 1 : 0

  triggers = {
    # Configuration triggers
    config_source = local.use_ssm_config ? var.chains_config_ssm_parameter : var.chains_config_yaml_path
    docker_image  = var.docker_image

    # Polling mode configuration
    polling_enabled  = var.polling_enabled
    async_processing = var.async_processing

    # Tags for filtering (hashed for change detection)
    required_tags_hash = sha256(jsonencode(var.required_sg_tags))

    # Polling parameters
    polling_interval = coalesce(var.polling_interval_seconds, 15)
    max_duration     = coalesce(var.max_polling_duration_seconds, 7200)
    max_parallel     = var.max_parallel_chains
  }

  provisioner "local-exec" {
    command     = local.docker_command_async
    working_dir = path.module

    environment = {
      AWS_REGION               = var.aws_region
      POLLING_ENABLED          = tostring(var.polling_enabled)
      ASYNC_PROCESSING         = tostring(var.async_processing)
      REQUIRED_SG_TAGS         = jsonencode(var.required_sg_tags)
      POLLING_INTERVAL_SECONDS = tostring(coalesce(var.polling_interval_seconds, 15))
      MAX_POLLING_DURATION     = tostring(coalesce(var.max_polling_duration_seconds, 7200))
      MAX_PARALLEL_CHAINS      = tostring(var.max_parallel_chains)
    }

    on_failure = continue
  }
}
