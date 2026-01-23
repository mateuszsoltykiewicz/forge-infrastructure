# ==============================================================================
# Local Values - Lambda Log Transformer Module
# ==============================================================================

locals {
  # Function name construction (Pattern A)
  function_name = "${var.common_prefix}-log-transformer-${var.environment}"

  # Resource tags merged from Pattern A
  default_tags = merge(
    var.common_tags,
    {
      Module      = "compute/lambda-log-transformer"
      Environment = var.environment
    }
  )
}
