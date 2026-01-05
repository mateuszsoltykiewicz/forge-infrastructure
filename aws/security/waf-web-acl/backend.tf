# ========================================
# Terraform Backend Configuration
# ========================================
#
# Uncomment and configure this block to use remote state storage.
# This is recommended for team collaboration and production environments.
#
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "security/waf-web-acl/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-locks"
#   }
# }
