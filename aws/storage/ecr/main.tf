#####################################################################
# ECR Module - Main Resources
#####################################################################

#####################################################################
# ECR Repository
#####################################################################

resource "aws_ecr_repository" "main" {
  name                 = local.repository_name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  # Image scanning configuration
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  # Encryption configuration
  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.kms_key_arn
  }

  tags = local.all_tags

  lifecycle {
    # Prevent accidental deletion of production repositories
    prevent_destroy = false

    precondition {
      condition     = !local.kms_required_but_missing
      error_message = "kms_key_arn must be provided when encryption_type is KMS"
    }
  }
}

#####################################################################
# Enhanced Image Scanning (AWS Inspector)
#####################################################################

resource "aws_ecr_registry_scanning_configuration" "enhanced" {
  count = local.is_enhanced_scanning ? 1 : 0

  scan_type = "ENHANCED"

  rule {
    scan_frequency = var.scan_frequency

    repository_filter {
      filter      = local.repository_name
      filter_type = "WILDCARD"
    }
  }
}

#####################################################################
# Lifecycle Policy
#####################################################################

resource "aws_ecr_lifecycle_policy" "main" {
  count = local.should_create_lifecycle_policy ? 1 : 0

  repository = aws_ecr_repository.main.name

  policy = jsonencode(local.lifecycle_policy)

  depends_on = [aws_ecr_repository.main]
}

#####################################################################
# Repository Policy
#####################################################################

resource "aws_ecr_repository_policy" "main" {
  count = local.should_create_repository_policy ? 1 : 0

  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = local.all_policy_statements
  })

  depends_on = [aws_ecr_repository.main]

  lifecycle {
    precondition {
      condition     = !local.cross_account_enabled_but_no_accounts
      error_message = "cross_account_ids must be provided when allow_cross_account_pull is true"
    }

    precondition {
      condition     = length(local.all_policy_statements) > 0
      error_message = "At least one policy statement must be provided"
    }
  }
}

#####################################################################
# Replication Configuration
#####################################################################

resource "aws_ecr_replication_configuration" "main" {
  count = local.should_enable_replication ? 1 : 0

  replication_configuration {
    rule {
      dynamic "destination" {
        for_each = var.replication_destinations

        content {
          region      = destination.value.region
          registry_id = destination.value.registry_id
        }
      }

      repository_filter {
        filter      = local.repository_name
        filter_type = "PREFIX_MATCH"
      }
    }
  }

  depends_on = [aws_ecr_repository.main]
}

#####################################################################
# Pull Through Cache
#####################################################################

resource "aws_ecr_pull_through_cache_rule" "main" {
  count = local.should_enable_pull_through_cache ? 1 : 0

  ecr_repository_prefix = "${local.repository_name}/cache"
  upstream_registry_url = local.upstream_registry_url

  lifecycle {
    precondition {
      condition     = !local.pull_through_cache_enabled_but_no_upstream
      error_message = "upstream_registry must be provided when enable_pull_through_cache is true"
    }
  }
}

#####################################################################
# CloudWatch Alarms for Scan Findings
#####################################################################

# Alarm for critical/high severity findings
resource "aws_cloudwatch_metric_alarm" "scan_findings" {
  count = local.should_create_scan_alarm ? 1 : 0

  alarm_name          = "${local.repository_name}-critical-vulnerabilities"
  alarm_description   = "Alert when critical or high severity vulnerabilities are found in ${local.repository_name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ImageScanFindings"
  namespace           = "AWS/ECR"
  period              = 300
  statistic           = "Maximum"
  threshold           = var.scan_findings_alarm_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    RepositoryName = aws_ecr_repository.main.name
  }

  alarm_actions = [var.alarm_sns_topic_arn]
  ok_actions    = [var.alarm_sns_topic_arn]

  tags = local.all_tags

  lifecycle {
    precondition {
      condition     = !local.alarm_enabled_but_no_topic
      error_message = "alarm_sns_topic_arn must be provided when create_scan_findings_alarm is true"
    }
  }
}

#####################################################################
# Validation Warnings
#####################################################################

# Null resource for validation warnings
resource "null_resource" "validation_warnings" {
  count = 1

  triggers = {
    mutable_tags_warning   = local.production_using_mutable_tags ? "WARNING: Production using MUTABLE tags" : "OK"
    basic_scan_warning     = local.production_using_basic_scan ? "WARNING: Production using BASIC scanning" : "OK"
    no_kms_warning         = local.production_without_kms ? "WARNING: Production not using KMS encryption" : "OK"
  }
}

# Output warnings during plan
resource "terraform_data" "warnings" {
  count = local.production_using_mutable_tags || local.production_using_basic_scan || local.production_without_kms ? 1 : 0

  triggers_replace = {
    warnings = jsonencode({
      mutable_tags = local.production_using_mutable_tags ? "Production repositories should use IMMUTABLE tags to prevent accidental overwrites" : null
      basic_scan   = local.production_using_basic_scan ? "Production repositories should use ENHANCED scanning for comprehensive vulnerability detection" : null
      no_kms       = local.production_without_kms ? "Production repositories should use KMS encryption for compliance" : null
    })
  }
}
