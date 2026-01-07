# ==============================================================================
# NAT Gateway Module - Version Constraints
# ==============================================================================
# Defines minimum required versions for Terraform and providers.
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.9, < 7.0"
    }
  }
}
