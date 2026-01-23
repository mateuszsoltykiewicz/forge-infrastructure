# ==============================================================================
# Data Sources - Lambda Log Transformer Module
# ==============================================================================

# Current AWS region
data "aws_region" "current" {}

# Current AWS account ID
data "aws_caller_identity" "current" {}
