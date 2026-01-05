#####################################################################
# ECR Module - Local Values
#####################################################################

locals {
  #####################################################################
  # Naming Strategy
  #####################################################################

  # Repository name based on customer context
  repository_name = var.repository_name != null ? var.repository_name : (
    var.architecture_type == "forge"
      ? "${var.customer_id}/${var.environment}"
      : "${var.customer_id}-${var.region}-${var.environment}"
  )

  #####################################################################
  # Feature Flags
  #####################################################################

  # Encryption
  is_kms_encrypted = var.encryption_type == "KMS"
  kms_key_provided = var.kms_key_arn != null

  # Scanning
  is_enhanced_scanning = var.image_scanning_configuration_type == "ENHANCED"
  is_continuous_scan   = var.scan_frequency == "CONTINUOUS_SCAN"

  # Lifecycle
  should_create_lifecycle_policy = var.enable_lifecycle_policy

  # Policy
  should_create_repository_policy = var.create_repository_policy || var.allow_cross_account_pull || var.allow_lambda_pull

  # Replication
  should_enable_replication = var.enable_replication && length(var.replication_destinations) > 0

  # Pull through cache
  should_enable_pull_through_cache = var.enable_pull_through_cache && var.upstream_registry != null

  # Monitoring
  should_create_scan_alarm = var.create_scan_findings_alarm && var.alarm_sns_topic_arn != null

  #####################################################################
  # Environment-based Defaults
  #####################################################################

  is_production = contains(["production", "prod"], var.environment)
  is_staging    = var.environment == "staging"
  is_development = contains(["dev", "development"], var.environment)

  # Default lifecycle policy image counts by environment
  default_max_image_count = (
    var.max_image_count != null ? var.max_image_count : (
      local.is_production ? 30 :
      local.is_staging ? 10 :
      5  # development
    )
  )

  # Recommended image tag mutability by environment
  recommended_tag_mutability = local.is_production ? "IMMUTABLE" : "MUTABLE"
  tag_mutability_is_recommended = var.image_tag_mutability == local.recommended_tag_mutability

  # Recommended scanning configuration
  recommended_scanning = local.is_production ? "ENHANCED" : "BASIC"

  #####################################################################
  # Lifecycle Policy Rules
  #####################################################################

  # Default lifecycle policy
  default_lifecycle_policy = {
    rules = [
      # Rule 1: Keep only the last N tagged images
      {
        rulePriority = 1
        description  = "Keep last ${local.default_max_image_count} tagged images"
        selection = {
          tagStatus   = "tagged"
          tagPrefixList = ["v", "prod", "staging", "dev", "latest"]
          countType   = "imageCountMoreThan"
          countNumber = local.default_max_image_count
        }
        action = {
          type = "expire"
        }
      },
      # Rule 2: Expire untagged images after N days
      {
        rulePriority = 2
        description  = "Expire untagged images after ${var.untagged_image_retention_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_retention_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  }

  # Use custom or default lifecycle policy
  lifecycle_policy = var.lifecycle_policy_rules != null ? var.lifecycle_policy_rules : local.default_lifecycle_policy

  #####################################################################
  # Repository Policy
  #####################################################################

  # Cross-account pull policy statements
  cross_account_pull_statements = var.allow_cross_account_pull && length(var.cross_account_ids) > 0 ? [
    {
      sid    = "AllowCrossAccountPull"
      effect = "Allow"
      principals = {
        aws = [for account_id in var.cross_account_ids : "arn:aws:iam::${account_id}:root"]
      }
      actions = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }
  ] : []

  # Lambda pull policy statement
  lambda_pull_statements = var.allow_lambda_pull ? [
    {
      sid    = "AllowLambdaPull"
      effect = "Allow"
      principals = {
        service = ["lambda.amazonaws.com"]
      }
      actions = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }
  ] : []

  # Combine all policy statements
  all_policy_statements = concat(
    var.repository_policy_statements,
    local.cross_account_pull_statements,
    local.lambda_pull_statements
  )

  #####################################################################
  # Pull Through Cache Configuration
  #####################################################################

  upstream_registry_urls = {
    docker-hub                   = "registry-1.docker.io"
    github-container-registry    = "ghcr.io"
    kubernetes-registry          = "registry.k8s.io"
    quay                        = "quay.io"
  }

  upstream_registry_url = var.upstream_registry != null ? local.upstream_registry_urls[var.upstream_registry] : null

  #####################################################################
  # Cost Estimation
  #####################################################################

  # ECR pricing (as of 2024)
  # - Storage: $0.10 per GB per month
  # - Data Transfer: Standard AWS data transfer pricing
  # - Basic Scanning: Free
  # - Enhanced Scanning: ~$0.09 per image per month
  # - KMS: $1 per key per month

  estimated_monthly_cost = {
    storage_per_gb        = 0.10
    enhanced_scan_per_image = local.is_enhanced_scanning ? 0.09 : 0.00
    kms_encryption        = local.is_kms_encrypted ? 1.00 : 0.00
    
    notes = [
      "Storage: $0.10 per GB per month",
      local.is_enhanced_scanning ? "Enhanced scanning: ~$0.09 per image per month" : "Basic scanning: Free",
      local.is_kms_encrypted ? "KMS encryption: $1.00 per key per month" : "AES256 encryption: Free",
      "Data transfer: Standard AWS pricing applies",
      "First 500 MB/month storage is free (AWS Free Tier)"
    ]
  }

  #####################################################################
  # Tagging Strategy
  #####################################################################

  default_tags = var.enable_default_tags ? {
    Customer         = var.customer_name
    CustomerId       = var.customer_id
    Environment      = var.environment
    Architecture     = var.architecture_type
    PlanTier         = var.plan_tier
    Region           = var.region
    ManagedBy        = "terraform"
    Module           = "ecr"
    RepositoryName   = local.repository_name
    ImageTagMutability = var.image_tag_mutability
    ScanOnPush       = tostring(var.scan_on_push)
    ScanType         = var.image_scanning_configuration_type
  } : {}

  # Merge default tags with user-provided tags
  all_tags = merge(local.default_tags, var.tags)

  #####################################################################
  # Validation Checks
  #####################################################################

  # KMS validation
  kms_required_but_missing = local.is_kms_encrypted && !local.kms_key_provided

  # Lifecycle policy validation
  has_custom_lifecycle_policy = var.lifecycle_policy_rules != null

  # Cross-account validation
  cross_account_enabled_but_no_accounts = var.allow_cross_account_pull && length(var.cross_account_ids) == 0

  # Pull through cache validation
  pull_through_cache_enabled_but_no_upstream = var.enable_pull_through_cache && var.upstream_registry == null

  # Alarm validation
  alarm_enabled_but_no_topic = var.create_scan_findings_alarm && var.alarm_sns_topic_arn == null

  # Production best practices validation
  production_using_mutable_tags = local.is_production && var.image_tag_mutability == "MUTABLE"
  production_using_basic_scan   = local.is_production && !local.is_enhanced_scanning
  production_without_kms        = local.is_production && !local.is_kms_encrypted

  #####################################################################
  # Integration Outputs
  #####################################################################

  # EKS integration
  eks_image_pull_config = {
    registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
    repository = local.repository_name
    full_uri = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.repository_name}"
  }

  # Lambda container image config
  lambda_container_config = {
    image_uri = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.repository_name}:latest"
  }

  # CodeBuild integration
  codebuild_config = {
    registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
    repository = local.repository_name
    credentials_type = "SERVICE_ROLE"  # Use CodeBuild service role
  }

  #####################################################################
  # Security and Compliance
  #####################################################################

  compliance_status = {
    encrypted                = true  # ECR always encrypts at rest
    encryption_type          = var.encryption_type
    customer_managed_kms     = local.is_kms_encrypted
    image_scanning_enabled   = var.scan_on_push
    scanning_type            = var.image_scanning_configuration_type
    immutable_tags           = var.image_tag_mutability == "IMMUTABLE"
    lifecycle_policy_enabled = var.enable_lifecycle_policy
    cross_account_access     = var.allow_cross_account_pull
    
    recommendations = concat(
      local.production_using_mutable_tags ? ["Production should use IMMUTABLE tags"] : [],
      local.production_using_basic_scan ? ["Production should use ENHANCED scanning"] : [],
      local.production_without_kms ? ["Production should use KMS encryption"] : [],
      !var.scan_on_push ? ["Enable scan_on_push for security compliance"] : []
    )
  }
}

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}
