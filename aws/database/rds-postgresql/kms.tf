# ==============================================================================
# RDS PostgreSQL Module - KMS Key
# ==============================================================================
# This file creates a KMS key for RDS encryption (storage, Performance Insights, SSM).
# ==============================================================================

# ------------------------------------------------------------------------------
# KMS Key
# ------------------------------------------------------------------------------

resource "aws_kms_key" "rds" {
  description             = "KMS key for ${local.db_identifier} RDS encryption"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = var.enable_kms_key_rotation

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.db_identifier}-kms"
    }
  )

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow RDS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "rds.${data.aws_region.current.id}.amazonaws.com"
          }
        }
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.id}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/rds/*"
          }
        }
      },
      {
        Sid    = "Allow SSM Parameter Store"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# KMS Alias
# ------------------------------------------------------------------------------

resource "aws_kms_alias" "rds" {
  name          = "alias/${local.db_identifier}"
  target_key_id = aws_kms_key.rds.key_id
}
