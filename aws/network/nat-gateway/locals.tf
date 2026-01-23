# ==============================================================================
# NAT Gateway Module - Local Values
# ==============================================================================

locals {
  # Resource naming
  nat_name_prefix = "${var.common_prefix}-nat-gw"

  # Merged tags
  merged_tags = merge(
    var.common_tags,
    {
      TerraformModule = "forge/aws/network/nat-gateway"
      Module          = "nat-gateway"
      ManagedBy       = "Terraform"
      Component       = "Network"
      Purpose         = "Private-Subnet-Egress"
      CostCenter      = "Infrastructure"
    }
  )
}
