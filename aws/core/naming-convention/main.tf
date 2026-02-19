# ==============================================================================
# AWS Naming Convention Module
# ==============================================================================
# Centralized naming sanitization for all AWS resources
# Pattern: {customer_code}-{project_code}-{dr_code}-{region_code}
# Example: san-cro-p-use1 (customer-project-primary-us-east-1)
# ==============================================================================


# {customer}/{project}/{dr_type}/{region}/{workspace}/{environment}/{service_name}

locals {
  # ------------------------------------------------------------------------------
  # Region Code Mapping
  # ------------------------------------------------------------------------------
  # 4-character codes for AWS regions
  region_codes = {
    # US Regions
    "us-east-1" = "use1"
    "us-east-2" = "use2"
    "us-west-1" = "usw1"
    "us-west-2" = "usw2"

    # EU Regions
    "eu-west-1"    = "euw1"
    "eu-west-2"    = "euw2"
    "eu-west-3"    = "euw3"
    "eu-central-1" = "euc1"
    "eu-central-2" = "euc2"
    "eu-north-1"   = "eun1"

    # Other regions (extensible)
    "ap-south-1"     = "aps1"
    "ap-southeast-1" = "apse1"
    "ap-southeast-2" = "apse2"
    "ap-northeast-1" = "apne1"
  }

  # ------------------------------------------------------------------------------
  # Base Components (lowercase, truncated)
  # ------------------------------------------------------------------------------

  # Customer code: first 3 letters, lowercase
  customer_code = lower(substr(var.customer_name, 0, 3))

  # Project code: first 3 letters, lowercase
  project_code = lower(substr(var.project_name, 0, 3))

  # DR mode: p = primary, s = secondary
  dr_code = var.current_region == var.primary_aws_region ? "p" : "s"

  # Region code: 4-letter abbreviation
  region_code = lookup(local.region_codes, var.current_region, "unkn")

  # ------------------------------------------------------------------------------
  # Common Prefix (Base Pattern)
  # ------------------------------------------------------------------------------
  # Pattern: {customer_code}-{project_code}-{dr_code}-{region_code}
  # Example: san-cro-p-use1
  common_prefix = "${local.customer_code}-${local.project_code}-${local.dr_code}-${local.region_code}"

  # ------------------------------------------------------------------------------
  # Service-Specific Prefixes (AWS Constraint Compliance)
  # ------------------------------------------------------------------------------

  # RDS: max 63 chars for DB instance identifier (lowercase, alphanumeric, hyphens)
  # Pattern: {common_prefix} (already lowercase)
  prefix_rds = lower(substr(local.common_prefix, 0, 63))

  # ElastiCache Redis: max 40 chars for replication group ID (lowercase, alphanumeric, hyphens)
  # Pattern: {common_prefix}-redis
  prefix_redis = lower(substr("${local.common_prefix}-redis", 0, 40))

  # ALB: max 32 chars for ALB name (lowercase, alphanumeric, hyphens)
  # Pattern: {common_prefix}-alb
  prefix_alb = lower(substr("${local.common_prefix}-alb", 0, 32))

  # IAM: max 64 chars for role names, but CloudWatch log role prefix can be long
  # We limit to 38 chars to leave room for suffixes like "-cloudwatch-logs-"
  # Pattern: {common_prefix}
  prefix_iam = lower(substr(local.common_prefix, 0, 38))

  # EKS: max 100 chars for cluster name (alphanumeric, hyphens)
  # Pattern: {common_prefix}-eks
  prefix_eks = lower(substr("${local.common_prefix}-eks", 0, 100))

  # KMS: max 256 chars for alias (alphanumeric, hyphens, underscores, slashes)
  # Pattern: alias/{common_prefix}
  prefix_kms = lower(substr(local.common_prefix, 0, 250))

  # S3: max 63 chars for bucket name (lowercase, alphanumeric, hyphens, dots)
  # Pattern: {common_prefix}
  prefix_s3 = lower(substr(local.common_prefix, 0, 63))

  # Security Groups: max 255 chars for name (alphanumeric, hyphens, underscores, spaces)
  # Pattern: {common_prefix}
  prefix_sg = lower(substr(local.common_prefix, 0, 255))

  # CloudWatch: max 512 chars for log group name
  # Pattern: /aws/{service}/{common_prefix}
  prefix_cloudwatch = lower(substr(local.common_prefix, 0, 500))

  # VPN: max 255 chars for Client VPN endpoint name
  # Pattern: {common_prefix}-vpn
  prefix_vpn = lower(substr("${local.common_prefix}-vpn", 0, 255))
}
