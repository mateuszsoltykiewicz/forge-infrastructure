# ==============================================================================
# ElastiCache Redis Module - Provider and Terraform Version Requirements
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.9.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

# Note: Provider configuration should be defined in the root module, not here.
# This module expects the AWS provider to be configured by the caller.
