# ==============================================================================
# EKS Module - Backend Configuration
# ==============================================================================
# This file configures the Terraform state backend using Amazon S3.
#
# IMPORTANT: This backend configuration is COMMENTED OUT until the bootstrap
# process creates the S3 bucket and DynamoDB table.
#
# After bootstrap completion:
# 1. Uncomment the terraform block below
# 2. Update the bucket name to match your Forge deployment
# 3. Update the region to match your deployment region
# 4. Run: terraform init -migrate-state
# ==============================================================================

# terraform {
#   backend "s3" {
#     bucket         = "forge-production-terraform-state"  # Update this
#     key            = "eks/terraform.tfstate"
#     region         = "us-east-1"                         # Update this
#     encrypt        = true
#     dynamodb_table = "forge-production-terraform-locks"  # Update this
#
#     # Optional: Use a specific profile or role
#     # profile = "forge-production"
#   }
# }
