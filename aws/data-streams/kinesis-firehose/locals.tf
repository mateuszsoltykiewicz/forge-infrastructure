# ==============================================================================
# Local Values - Kinesis Firehose Module
# ==============================================================================

locals {
  # Firehose IAM role name
  firehose_role_name = "${var.common_prefix}-${var.environment}-firehose-role"

  # Stream names (must match Lambda source detection regex)
  stream_names = {
    waf                = "aws-waf-logs-${var.common_prefix}-${var.environment}"  # AWS WAF requires "aws-waf-logs-" prefix
    vpc                = "${var.common_prefix}-vpc-firehose-stream-${var.environment}"
    rds                = "${var.common_prefix}-rds-firehose-stream-${var.environment}"
    eks_events         = "${var.common_prefix}-eks-events-firehose-stream-${var.environment}"
    eks_pods           = "${var.common_prefix}-eks-pods-firehose-stream-${var.environment}"
    metrics            = "${var.common_prefix}-metrics-firehose-stream-${var.environment}"
    cloudwatch_generic = "${var.common_prefix}-cloudwatch-generic-firehose-stream-${var.environment}"
  }

  # Default Glue database name if not provided
  glue_database = var.glue_database_name != null ? var.glue_database_name : "${var.common_prefix}_logs"
}
