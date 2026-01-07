# ==============================================================================
# Route 53 Hosted Zone Module - Backend Configuration
# ==============================================================================
# This file defines the Terraform backend for storing state.
# Uncomment and configure when using this module directly (not recommended).
# ==============================================================================

# terraform {
#   backend "s3" {
#     bucket         = "forge-production-terraform-state"
#     key            = "network/route53-zone/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "forge-production-terraform-lock"
#   }
# }
