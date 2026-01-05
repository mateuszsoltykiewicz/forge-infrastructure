#####################################################################
# ECR Module - Backend Configuration
#####################################################################

# Backend configuration for Terraform state storage
# Uncomment and configure for your environment

# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "storage/ecr/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#     
#     # Optional: Use SSO profile
#     # profile = "your-aws-profile"
#   }
# }
