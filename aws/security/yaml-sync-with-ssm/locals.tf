locals {
  module_name = "yaml-sync-with-ssm"

  module_tags = {
    TerraformModule = "forge/aws/security/yaml-sync-with-ssm"
    Module          = local.module_name
    Type            = "config-sync"
  }

  all_tags = merge(
    var.common_tags,
    local.module_tags
  )

  # Compute YAML file hash for change detection
  yaml_file_hash = var.trigger_on_yaml_change ? (
    fileexists(var.yaml_file_path) ? sha256(file(var.yaml_file_path)) : ""
  ) : ""

  # Docker command arguments based on sync mode
  sync_args = {
    upload = concat(
      ["upload", "/data/${basename(var.yaml_file_path)}"],
      ["--parameter", var.ssm_parameter_name],
      ["--region", var.aws_region],
      ["--description", var.parameter_description],
      var.validate_before_upload ? ["--validate"] : [],
      var.force_sync ? ["--force"] : []
    )

    download = concat(
      ["download", "/data/${basename(var.yaml_file_path)}"],
      ["--parameter", var.ssm_parameter_name],
      ["--region", var.aws_region],
      var.force_sync ? ["--force"] : []
    )

    none = []
  }

  # Full Docker command - mount .aws to non-root user home directory
  docker_command = var.sync_mode != "none" ? format(
    "docker run --rm -v $${HOME}/.aws:/home/syncer/.aws:ro -v \"%s:/data\" %s %s %s",
    abspath(dirname(var.yaml_file_path)),
    var.docker_image,
    var.sync_mode,
    join(" ", concat(
      ["/data/${basename(var.yaml_file_path)}"],
      ["--parameter", var.ssm_parameter_name],
      ["--region", var.aws_region],
      ["--description", "'${replace(var.parameter_description, "'", "'\\''")}'"],
      var.validate_before_upload && var.sync_mode == "upload" ? ["--validate"] : [],
      var.force_sync ? ["--force"] : []
    ))
  ) : "echo 'YAML-SSM sync disabled (mode=none)'"
}
