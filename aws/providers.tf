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
      version = "5.95.0" # Exact version required by EKS module 20.x (>= 5.95.0, < 6.0.0)
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
  }
}

# ==============================================================================
# AWS Provider Configuration
# ==============================================================================

# Primary region provider
provider "aws" {
  region = var.current_region
}

# Disaster Recovery region provider (for cross-region replication)
provider "aws" {
  alias  = "dr_region"
  region = var.secondary_aws_region
}

# ==============================================================================
# Provider Configuration Best Practices:
# ==============================================================================
# - Use specific provider versions to ensure reproducibility
# - Configure default tags for all AWS resources
# - Set region explicitly to avoid ambiguity
# - DR provider enables cross-region S3 replication for HIPAA compliance
# ==============================================================================
