#####################################################################
# ECR Module - Outputs
#####################################################################

#####################################################################
# Repository Identifiers
#####################################################################

output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.main.name
}

output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.main.arn
}

output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.main.repository_url
}

output "registry_id" {
  description = "Registry ID (AWS account ID)"
  value       = aws_ecr_repository.main.registry_id
}

#####################################################################
# Repository Configuration
#####################################################################

output "image_tag_mutability" {
  description = "Image tag mutability setting"
  value       = aws_ecr_repository.main.image_tag_mutability
}

output "encryption_type" {
  description = "Encryption type (AES256 or KMS)"
  value       = var.encryption_type
}

output "kms_key_arn" {
  description = "KMS key ARN used for encryption (if KMS encryption is enabled)"
  value       = var.kms_key_arn
}

#####################################################################
# Scanning Configuration
#####################################################################

output "scan_on_push" {
  description = "Whether images are scanned on push"
  value       = var.scan_on_push
}

output "scanning_type" {
  description = "Type of image scanning (BASIC or ENHANCED)"
  value       = var.image_scanning_configuration_type
}

output "scan_frequency" {
  description = "Scan frequency for enhanced scanning"
  value       = var.scan_frequency
}

#####################################################################
# Lifecycle Policy
#####################################################################

output "lifecycle_policy_enabled" {
  description = "Whether lifecycle policy is enabled"
  value       = var.enable_lifecycle_policy
}

output "lifecycle_policy" {
  description = "Lifecycle policy configuration"
  value       = local.should_create_lifecycle_policy ? local.lifecycle_policy : null
}

output "max_image_count" {
  description = "Maximum number of tagged images to keep"
  value       = local.default_max_image_count
}

output "untagged_retention_days" {
  description = "Number of days to retain untagged images"
  value       = var.untagged_image_retention_days
}

#####################################################################
# Repository Policy
#####################################################################

output "repository_policy_enabled" {
  description = "Whether repository policy is enabled"
  value       = local.should_create_repository_policy
}

output "cross_account_access_enabled" {
  description = "Whether cross-account access is enabled"
  value       = var.allow_cross_account_pull
}

output "cross_account_ids" {
  description = "List of AWS account IDs with pull access"
  value       = var.cross_account_ids
}

output "lambda_access_enabled" {
  description = "Whether Lambda access is enabled"
  value       = var.allow_lambda_pull
}

#####################################################################
# Replication
#####################################################################

output "replication_enabled" {
  description = "Whether replication is enabled"
  value       = local.should_enable_replication
}

output "replication_destinations" {
  description = "List of replication destinations"
  value       = var.replication_destinations
}

#####################################################################
# Pull Through Cache
#####################################################################

output "pull_through_cache_enabled" {
  description = "Whether pull-through cache is enabled"
  value       = local.should_enable_pull_through_cache
}

output "upstream_registry" {
  description = "Upstream registry for pull-through cache"
  value       = var.upstream_registry
}

output "upstream_registry_url" {
  description = "Upstream registry URL"
  value       = local.upstream_registry_url
}

#####################################################################
# Integration Configurations
#####################################################################

output "eks_integration" {
  description = "Configuration for EKS integration"
  value       = local.eks_image_pull_config
}

output "lambda_integration" {
  description = "Configuration for Lambda container images"
  value       = local.lambda_container_config
}

output "codebuild_integration" {
  description = "Configuration for AWS CodeBuild integration"
  value       = local.codebuild_config
}

#####################################################################
# Docker Commands
#####################################################################

output "docker_commands" {
  description = "Useful Docker commands for working with this repository"
  value = {
    login = "aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
    
    build = "docker build -t ${local.repository_name} ."
    
    tag = "docker tag ${local.repository_name}:latest ${aws_ecr_repository.main.repository_url}:latest"
    
    push = "docker push ${aws_ecr_repository.main.repository_url}:latest"
    
    pull = "docker pull ${aws_ecr_repository.main.repository_url}:latest"
    
    full_workflow = <<-EOT
      # Login to ECR
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com
      
      # Build image
      docker build -t ${local.repository_name} .
      
      # Tag image
      docker tag ${local.repository_name}:latest ${aws_ecr_repository.main.repository_url}:latest
      
      # Push image
      docker push ${aws_ecr_repository.main.repository_url}:latest
    EOT
  }
}

#####################################################################
# IAM Policy for Push Access
#####################################################################

output "push_policy_json" {
  description = "IAM policy document for push access to this repository"
  value = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRPushAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRRepositoryAccess"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = aws_ecr_repository.main.arn
      }
    ]
  })
}

#####################################################################
# IAM Policy for Pull Access
#####################################################################

output "pull_policy_json" {
  description = "IAM policy document for pull access to this repository"
  value = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRPullAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRRepositoryPullAccess"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = aws_ecr_repository.main.arn
      }
    ]
  })
}

#####################################################################
# Kubernetes ImagePullSecret
#####################################################################

output "kubernetes_image_pull_secret" {
  description = "Kubernetes secret configuration for pulling images from this ECR repository"
  value = {
    name = "${var.customer_id}-ecr-credentials"
    type = "kubernetes.io/dockerconfigjson"
    
    command_to_create = <<-EOT
      # Create ECR authentication token and Kubernetes secret
      kubectl create secret docker-registry ${var.customer_id}-ecr-credentials \
        --docker-server=${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com \
        --docker-username=AWS \
        --docker-password=$(aws ecr get-login-password --region ${var.region}) \
        --namespace=default
    EOT
    
    pod_spec_example = <<-EOT
      apiVersion: v1
      kind: Pod
      metadata:
        name: my-app
      spec:
        containers:
        - name: app
          image: ${aws_ecr_repository.main.repository_url}:latest
        imagePullSecrets:
        - name: ${var.customer_id}-ecr-credentials
    EOT
  }
}

#####################################################################
# Cost Estimation
#####################################################################

output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = {
    storage_per_gb          = "$${local.estimated_monthly_cost.storage_per_gb} per GB per month"
    enhanced_scanning       = local.is_enhanced_scanning ? "$${local.estimated_monthly_cost.enhanced_scan_per_image} per image per month" : "Free (Basic scanning)"
    kms_encryption          = local.is_kms_encrypted ? "$${local.estimated_monthly_cost.kms_encryption} per key per month" : "Free (AES256)"
    data_transfer           = "Standard AWS data transfer rates apply"
    
    notes = local.estimated_monthly_cost.notes
    
    example_costs = {
      small  = "5 images, 10 GB storage: ~$1/month (Basic scan, AES256)"
      medium = "20 images, 50 GB storage: ~$7/month (Enhanced scan, KMS)"
      large  = "100 images, 200 GB storage: ~$30/month (Enhanced scan, KMS)"
    }
  }
}

#####################################################################
# Compliance and Security
#####################################################################

output "compliance_status" {
  description = "Compliance and security configuration status"
  value       = local.compliance_status
}

output "security_best_practices" {
  description = "Security best practices checklist"
  value = {
    immutable_tags_enabled   = var.image_tag_mutability == "IMMUTABLE" ? "✅ Yes" : "❌ No (recommended for production)"
    scan_on_push_enabled     = var.scan_on_push ? "✅ Yes" : "❌ No"
    enhanced_scanning        = local.is_enhanced_scanning ? "✅ Yes" : "⚠️  No (recommended for production)"
    kms_encryption           = local.is_kms_encrypted ? "✅ Yes" : "⚠️  No (recommended for production/compliance)"
    lifecycle_policy_enabled = var.enable_lifecycle_policy ? "✅ Yes" : "❌ No"
    force_delete_disabled    = !var.force_delete ? "✅ Yes" : "⚠️  No (dangerous in production)"
  }
}

#####################################################################
# CloudWatch Metrics
#####################################################################

output "cloudwatch_metrics" {
  description = "CloudWatch metrics available for this repository"
  value = {
    namespace = "AWS/ECR"
    dimensions = {
      RepositoryName = aws_ecr_repository.main.name
    }
    available_metrics = [
      "RepositoryPullCount",
      "RepositoryPushCount",
      "ImageScanFindings"
    ]
  }
}

#####################################################################
# Summary Output
#####################################################################

output "repository_summary" {
  description = "Complete summary of the ECR repository configuration"
  value = {
    # Identity
    name          = aws_ecr_repository.main.name
    arn           = aws_ecr_repository.main.arn
    url           = aws_ecr_repository.main.repository_url
    registry_id   = aws_ecr_repository.main.registry_id
    region        = var.region
    
    # Configuration
    image_tag_mutability = var.image_tag_mutability
    encryption_type      = var.encryption_type
    scan_on_push         = var.scan_on_push
    scanning_type        = var.image_scanning_configuration_type
    
    # Features
    lifecycle_policy_enabled = var.enable_lifecycle_policy
    cross_account_access     = var.allow_cross_account_pull
    lambda_access            = var.allow_lambda_pull
    replication_enabled      = local.should_enable_replication
    pull_through_cache       = local.should_enable_pull_through_cache
    
    # Customer Context
    customer_id   = var.customer_id
    customer_name = var.customer_name
    environment   = var.environment
    plan_tier     = var.plan_tier
    
    # Tags
    tags = local.all_tags
  }
}
