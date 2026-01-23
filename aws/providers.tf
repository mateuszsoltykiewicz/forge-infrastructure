# ==============================================================================
# Terraform Provider Configuration
# ==============================================================================
# This file configures the AWS provider for multi-environment infrastructure
# deployment in us-east-1.
# ==============================================================================

terraform {
  required_version = "~> 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.0"
    }
  }
}

# ==============================================================================
# AWS Provider Configuration
# ==============================================================================

provider "aws" {
  region = var.current_region
}

# ==============================================================================
# Provider Configuration Best Practices:
# ==============================================================================
# - Use specific provider versions to ensure reproducibility
# - Configure default tags for all AWS resources
# - Set region explicitly to avoid ambiguity
# ==============================================================================
