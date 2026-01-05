# ==============================================================================
# Terraform Backend Configuration (Forge VPC Module)
# ==============================================================================
# This file configures the S3 backend for storing Terraform state remotely.
# 
# NOTE: This backend configuration is commented out by default because:
# 1. The bootstrap module must be run FIRST to create the S3 bucket and DynamoDB table
# 2. After bootstrap, uncomment this configuration and run `terraform init -migrate-state`
# ==============================================================================

# Uncomment after running bootstrap module:
#
# terraform {
#   backend "s3" {
#     # S3 Bucket Configuration
#     bucket = "forge-production-terraform-state"
#     key    = "modules/network/vpc/terraform.tfstate"
#     region = "us-east-1"
#     
#     # State Locking (DynamoDB)
#     dynamodb_table = "forge-production-terraform-locks"
#     
#     # Encryption
#     encrypt = true
#     kms_key_id = "alias/forge-terraform-state"
#     
#     # Access Configuration
#     # role_arn = "arn:aws:iam::ACCOUNT_ID:role/TerraformStateRole"
#   }
# }

# ==============================================================================
# Backend Configuration Instructions:
# ==============================================================================
# 
# STEP 1: Run Bootstrap Module First
# ----------------------------------
# cd infrastructure/terraform/bootstrap
# terraform init
# terraform plan
# terraform apply
# 
# This creates:
# - S3 bucket: forge-production-terraform-state
# - DynamoDB table: forge-production-terraform-locks
# - KMS key: alias/forge-terraform-state
# 
# STEP 2: Get Backend Values from Bootstrap Outputs
# -------------------------------------------------
# terraform output state_bucket_id        # Use for 'bucket'
# terraform output dynamodb_table_id      # Use for 'dynamodb_table'
# terraform output kms_state_alias        # Use for 'kms_key_id'
# 
# STEP 3: Uncomment Backend Configuration Above
# --------------------------------------------
# Update the values with actual bootstrap outputs
# 
# STEP 4: Migrate State to S3
# ---------------------------
# terraform init -migrate-state
# 
# This will migrate local state to S3 backend
# 
# ==============================================================================
# Customer-Specific Backends (Dedicated Architecture):
# ==============================================================================
# 
# For dedicated customer VPCs, use customer-specific state paths:
# 
# key = "customers/{customer_name}/network/vpc/terraform.tfstate"
# 
# Examples:
# - Shared Forge VPC: "modules/network/vpc/terraform.tfstate"
# - Customer VPC (Pro): "customers/sanofi/network/vpc/terraform.tfstate"
# - Customer VPC (Enterprise): "customers/acme/us-east-1/network/vpc/terraform.tfstate"
# 
# ==============================================================================
