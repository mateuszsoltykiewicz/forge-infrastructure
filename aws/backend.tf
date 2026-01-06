# ==============================================================================
# Terraform Backend Configuration - S3 + DynamoDB
# ==============================================================================
# This file configures the remote backend for Terraform state management.
# State is stored in S3 with DynamoDB for state locking.
#
# PREREQUISITES (manual setup required):
# 1. Create S3 bucket: insighthealth-terraform-state-us-east-1
# 2. Enable versioning on the bucket
# 3. Enable server-side encryption (AES-256 or KMS)
# 4. Create DynamoDB table: terraform-state-lock
# 5. Set partition key: LockID (String)
#
# AWS CLI commands to create backend resources:
# ```
# aws s3api create-bucket \
#   --bucket insighthealth-terraform-state-us-east-1 \
#   --region us-east-1
#
# aws s3api put-bucket-versioning \
#   --bucket insighthealth-terraform-state-us-east-1 \
#   --versioning-configuration Status=Enabled
#
# aws s3api put-bucket-encryption \
#   --bucket insighthealth-terraform-state-us-east-1 \
#   --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
#
# aws dynamodb create-table \
#   --table-name terraform-state-lock \
#   --attribute-definitions AttributeName=LockID,AttributeType=S \
#   --key-schema AttributeName=LockID,KeyType=HASH \
#   --billing-mode PAY_PER_REQUEST \
#   --region us-east-1
# ```
# ==============================================================================

terraform {
  backend "s3" {
    bucket         = "insighthealth-terraform-state-us-east-1"
    key            = "forge/infrastructure/us-east-1/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    
    # Optional: Use KMS encryption instead of AES-256
    # kms_key_id = "arn:aws:kms:us-east-1:ACCOUNT_ID:key/KEY_ID"
  }
}

# ==============================================================================
# Backend Configuration Best Practices:
# ==============================================================================
# - Always enable versioning on S3 bucket for state recovery
# - Enable encryption at rest (AES-256 or KMS)
# - Use DynamoDB for state locking to prevent concurrent modifications
# - Set appropriate IAM policies for S3 bucket and DynamoDB table
# - Consider using separate state files per environment (dev, staging, prod)
# - Backup state files regularly to separate location
# ==============================================================================
