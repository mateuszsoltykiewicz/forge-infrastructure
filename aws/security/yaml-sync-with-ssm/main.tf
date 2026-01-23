terraform {
  required_version = ">= 1.6"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Null resource to execute yaml-sync-with-ssm
resource "null_resource" "yaml_ssm_sync" {
  count = var.sync_mode != "none" ? 1 : 0

  # Trigger sync when:
  # 1. Sync mode changes
  # 2. YAML file content changes (if enabled)
  # 3. SSM parameter name changes
  # 4. Docker image changes
  triggers = {
    sync_mode          = var.sync_mode
    yaml_file_hash     = local.yaml_file_hash
    ssm_parameter_name = var.ssm_parameter_name
    docker_image       = var.docker_image
    force_sync         = var.force_sync ? timestamp() : "false"
  }

  # Execute sync via local-exec
  provisioner "local-exec" {
    command     = local.docker_command
    working_dir = path.module

    environment = {
      AWS_REGION = var.aws_region
    }
  }
}
