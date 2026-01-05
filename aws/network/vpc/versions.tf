# ==============================================================================
# Terraform and Provider Version Requirements (Forge)
# ==============================================================================
# Locks provider versions for reproducible and stable deployments.
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

# ==============================================================================
# Forge Best Practices:
# ==============================================================================
# - Pin Terraform version to ensure team uses compatible CLI
# - Use version constraints (>= 6.9, < 7.0) to allow minor updates but block breaking changes
# - Review AWS provider CHANGELOG before upgrading major versions
# - Test module with minimum and maximum allowed provider versions
# - Document version requirements in module README
# ==============================================================================
