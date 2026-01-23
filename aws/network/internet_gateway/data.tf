# ------------------------------------------------------------------------------
# VPC Configuration (Required)
# ------------------------------------------------------------------------------

# Fetch the VPC details using the provided VPC ID
data "aws_vpc" "selected" {
  id = var.vpc_id
}