# ==============================================================================
# VPC Endpoint Module - Backend Configuration
# ==============================================================================
# This file defines the Terraform backend for storing state.
# Uncomment and configure when using this module directly (not recommended).
# ==============================================================================

# terraform {
#   backend "s3" {
#     bucket         = "forge-production-terraform-state"
#     key            = "network/vpc-endpoint/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "forge-production-terraform-lock"
#   }
# }
