# ==============================================================================
# Terraform Backend Configuration (Forge Subnet Module)
# ==============================================================================
# 
# IMPORTANT: Backend configuration is commented out by default.
# Uncomment after running the bootstrap module to create S3 bucket and DynamoDB table.
# 
# ==============================================================================

# Uncomment after running bootstrap module:
#
# terraform {
#   backend "s3" {
#     # S3 Bucket Configuration
#     bucket = "forge-production-terraform-state"
#     key    = "modules/network/subnet/terraform.tfstate"
#     region = "us-east-1"
#     
#     # State Locking (DynamoDB)
#     dynamodb_table = "forge-production-terraform-locks"
#     
#     # Encryption
#     encrypt = true
#     kms_key_id = "alias/forge-terraform-state"
#   }
# }

# ==============================================================================
# Customer-Specific State Paths:
# ==============================================================================
# 
# For dedicated customer subnets, use customer-specific paths:
# 
# Shared Forge Subnets:
# key = "modules/network/subnet/terraform.tfstate"
# 
# Customer Subnets (Pro):
# key = "customers/sanofi/network/subnet/terraform.tfstate"
# 
# Customer Subnets (Enterprise Multi-Region):
# key = "customers/acme/us-east-1/network/subnet/terraform.tfstate"
# 
# ==============================================================================
