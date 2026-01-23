# ==============================================================================
# ECR Module - Elastic Container Registry
# ==============================================================================
# Creates private ECR repositories for container images with encryption,
# scanning, and lifecycle policies.
# ==============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ------------------------------------------------------------------------------
# ECR Repository
# ------------------------------------------------------------------------------

resource "aws_ecr_repository" "main" {
  name                 = local.repository_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.encryption_type == "KMS" ? var.kms_key_arn : null
  }

  tags = merge(
    var.common_tags,
    {
      Name        = local.repository_name
      Component   = "ECR Repository"
      Environment = var.environment
      Purpose     = var.repository_purpose
    }
  )
}

# ------------------------------------------------------------------------------
# Lifecycle Policy (keep tagged + last N untagged)
# ------------------------------------------------------------------------------

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = var.keep_tag_prefixes
          countType     = "imageCountMoreThan"
          countNumber   = var.keep_tagged_images
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last ${var.keep_untagged_images} untagged images"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = var.keep_untagged_images
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# Repository Policy (IAM access control)
# ------------------------------------------------------------------------------

resource "aws_ecr_repository_policy" "main" {
  count      = length(var.allowed_principals) > 0 ? 1 : 0
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPull"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_principals
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      {
        Sid    = "AllowPush"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_push_principals
        }
        Action = [
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}
