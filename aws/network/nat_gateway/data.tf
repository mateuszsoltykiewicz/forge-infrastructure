# ==============================================================================
# NAT Gateway Module - Data Sources
# ==============================================================================
# Fetches current EIP usage and limits for validation.
# ==============================================================================

# ------------------------------------------------------------------------------
# Existing EIPs in Region
# ------------------------------------------------------------------------------
# Query all existing EIPs to calculate available capacity
# ------------------------------------------------------------------------------

data "aws_eips" "existing" {
  filter {
    name   = "domain"
    values = ["vpc"]
  }
}

# ------------------------------------------------------------------------------
# Service Quotas - EIP Limit (Optional)
# ------------------------------------------------------------------------------
# Note: Requires additional IAM permissions for servicequotas:GetServiceQuota
# If unavailable, falls back to default limit of 5
# ------------------------------------------------------------------------------

data "aws_servicequotas_service_quota" "eip_limit" {
  count = var.check_eip_quota ? 1 : 0

  service_code = "ec2"
  quota_code   = "L-0263D0A3" # Standard (VPC) Elastic IP addresses

  lifecycle {
    # Gracefully handle missing permissions
    postcondition {
      condition     = self.value > 0
      error_message = "Unable to fetch EIP quota. Ensure IAM permissions include servicequotas:GetServiceQuota or set check_eip_quota = false."
    }
  }
}
