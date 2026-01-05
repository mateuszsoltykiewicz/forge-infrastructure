#
# Application Load Balancer Module - Backend Configuration
# Purpose: Define remote state backend (commented out for module reusability)
#

# Backend configuration should be defined in the root module, not in reusable modules.
# Uncomment and configure this block in your root module's backend.tf file:

# terraform {
#   backend "s3" {
#     bucket         = "forge-production-terraform-state"
#     key            = "compute/alb/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "forge-terraform-state-lock"
#   }
# }
