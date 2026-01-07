# ==============================================================================
# NAT Gateway Module - Backend Configuration
# ==============================================================================
# S3 backend for Terraform state storage with DynamoDB locking.
# This configuration is COMMENTED OUT by default and should be enabled after
# the bootstrap module has created the S3 bucket and DynamoDB table.
# ==============================================================================

# terraform {
#   backend "s3" {
#     bucket         = "forge-production-terraform-state"
#     dynamodb_table = "forge-production-terraform-locks"
#     encrypt        = true
#     kms_key_id     = "alias/forge-terraform-state"
#     region         = "us-east-1"
#     
#     # State file path examples:
#     #
#     # Shared Forge infrastructure:
#     #   key = "modules/network/nat_gateway/terraform.tfstate"
#     #
#     # Customer dedicated VPC (local):
#     #   key = "customers/sanofi/network/nat_gateway/terraform.tfstate"
#     #
#     # Customer dedicated VPC (regional):
#     #   key = "customers/acme/us-east-1/network/nat_gateway/terraform.tfstate"
#   }
# }
