# ==============================================================================
# Terraform Version Requirements - VPN Certificate Generator Module
# ==============================================================================
# This module uses the dr_region provider alias for cross-region SSM backup
# ==============================================================================

terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.82.0"
      configuration_aliases = [aws.dr_region]
    }
  }
}
