# ==============================================================================
# ElastiCache Redis Module - KMS Key for Encryption
# ==============================================================================
# This file creates a KMS key for encrypting:
# - Redis data at rest
# - SSM SecureString parameters
# - CloudWatch logs
# ==============================================================================

# ------------------------------------------------------------------------------
# KMS Key for Redis Encryption
# ------------------------------------------------------------------------------

resource "aws_kms_key" "redis" {
  description             = "ElastiCache Redis ${local.replication_group_id} encryption key"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = var.enable_kms_key_rotation

  tags = merge(
    local.merged_tags,
    {
      Name    = "${local.replication_group_id}-encryption"
      Purpose = "Redis Encryption"
    }
  )
}

resource "aws_kms_alias" "redis" {
  name          = "alias/${local.replication_group_id}"
  target_key_id = aws_kms_key.redis.key_id
}

# ------------------------------------------------------------------------------
# KMS Key Policy
# ------------------------------------------------------------------------------

data "aws_iam_policy_document" "kms_key_policy" {
  # Allow root account full access
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Allow ElastiCache service to use the key
  statement {
    sid    = "Allow ElastiCache Service"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["elasticache.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["elasticache.${var.aws_region}.amazonaws.com"]
    }
  }

  # Allow CloudWatch Logs to use the key
  statement {
    sid    = "Allow CloudWatch Logs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant"
    ]

    resources = ["*"]

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }

  # Allow SSM to use the key
  statement {
    sid    = "Allow SSM Parameter Store"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key_policy" "redis" {
  key_id = aws_kms_key.redis.id
  policy = data.aws_iam_policy_document.kms_key_policy.json
}
