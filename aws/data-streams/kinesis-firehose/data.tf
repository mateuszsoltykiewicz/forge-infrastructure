# ==============================================================================
# Data Sources - Kinesis Firehose Module
# ==============================================================================

# Current AWS region
data "aws_region" "current" {}

# Current AWS account ID
data "aws_caller_identity" "current" {}
