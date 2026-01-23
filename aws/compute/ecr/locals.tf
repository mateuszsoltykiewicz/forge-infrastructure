# ==============================================================================
# Local Values - ECR Module
# ==============================================================================

locals {
  # Repository name construction (Pattern A)
  # Format: {common_prefix}-{repository_name}-{environment}
  # Example: forge-lambda-log-transformer-production
  repository_name = "${var.common_prefix}-${var.repository_name}-${var.environment}"
}
