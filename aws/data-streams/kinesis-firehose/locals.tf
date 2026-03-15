# ==============================================================================
# Local Values - Kinesis Firehose Module
# ==============================================================================

locals {

  # ============================================================================
  # SECTION 1: TAG MANAGEMENT (Pattern A)
  # ============================================================================

  # Module-specific tags (only Kinesis Firehose-specific metadata)
  module_tags = {
    TerraformModule = "forge/aws/data-streams/kinesis-firehose"
    Module          = "Kinesis Firehose"
    Family          = "Data Streams"
  }

  # Merge common tags from root + module-specific tags
  merged_tags = merge(
    var.common_tags,   # Common tags from root (ManagedBy, Region, Environment, etc.)
    local.module_tags, # Module-specific tags
  )

  # ============================================================================
  # SECTION 2: RESOURCE NAMING
  # ============================================================================
  # Note: common_prefix = "{customer}-{project}-{environment}"
  # For path-like naming: replace "-" with "/"
  # For IAM role names: use PascalCase (no hyphens)

  # Path-like prefix for resources (replace hyphens with slashes)
  path_prefix = replace(var.common_prefix, "-", "/")

  # PascalCase prefix for IAM role names (capitalize each word, remove hyphens)
  pascal_prefix = join("", [for part in split("-", var.common_prefix) : title(part)])

  # Firehose IAM role name (PascalCase)
  firehose_role_name = "${local.pascal_prefix}DataStreamsFirehoseRole"

  # Stream names - PascalCase naming convention (must match Lambda source detection regex)
  stream_names = {
    waf                = "aws-waf-logs-${var.common_prefix}" # AWS WAF requires "aws-waf-logs-" prefix
    vpc                = "${local.pascal_prefix}DataStreamsVpcFlowLogs"
    rds                = "${local.pascal_prefix}DataStreamsRdsLogs"
    eks_events         = "${local.pascal_prefix}DataStreamsEksEvents"
    eks_pods           = "${local.pascal_prefix}DataStreamsEksPods"
    metrics            = "${local.pascal_prefix}DataStreamsCloudwatchMetrics"
    cloudwatch_generic = "${local.pascal_prefix}DataStreamsCloudwatchGeneric"
  }

  # Default Glue database name if not provided
  glue_database = var.glue_database_name != null ? var.glue_database_name : "${var.common_prefix}_logs"
}
