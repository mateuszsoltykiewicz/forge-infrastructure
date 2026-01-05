# ==============================================================================
# Terraform and Provider Version Requirements (Forge)
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
# - Use version constraints to allow minor updates but block breaking changes
# - Review AWS provider CHANGELOG before upgrading major versions
# - Test module with minimum and maximum allowed provider versions
# ==============================================================================
