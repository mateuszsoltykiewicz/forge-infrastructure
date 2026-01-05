#
# Application Load Balancer Module - Version Constraints
# Purpose: Define required Terraform and provider versions
#

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.9.0"
    }
  }
}
