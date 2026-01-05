#####################################################################
# ECR Module - Variables
#
# Purpose: Container image registry with security scanning and lifecycle management
#
# Features:
# - Image vulnerability scanning (basic or enhanced)
# - Immutable image tags
# - KMS encryption
# - Cross-account pull access
# - Lifecycle policies for cost optimization
# - Repository policies for fine-grained access control
# - Replication to other regions
# - Image signing verification
#
# Integration:
# - EKS clusters
# - ECS/Fargate tasks
# - Lambda container images
# - CodePipeline/CodeBuild
# - Third-party CI/CD
#####################################################################

#####################################################################
# Customer Context Variables
#####################################################################

variable "customer_id" {
  description = "Unique identifier for the customer (e.g., 'acme-corp', 'contoso')"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.customer_id))
    error_message = "customer_id must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "customer_name" {
  description = "Human-readable name of the customer organization"
  type        = string
}

variable "architecture_type" {
  description = "Type of architecture deployment (forge, legacy, hybrid)"
  type        = string
  default     = "forge"

  validation {
    condition     = contains(["forge", "legacy", "hybrid"], var.architecture_type)
    error_message = "architecture_type must be one of: forge, legacy, hybrid"
  }
}

variable "plan_tier" {
  description = "Service plan tier (basic, pro, enterprise)"
  type        = string
  default     = "basic"

  validation {
    condition     = contains(["basic", "pro", "enterprise", "custom"], var.plan_tier)
    error_message = "plan_tier must be one of: basic, pro, enterprise, custom"
  }
}

variable "environment" {
  description = "Environment name (dev, staging, production, test)"
  type        = string

  validation {
    condition     = contains(["dev", "development", "staging", "production", "prod", "test"], var.environment)
    error_message = "environment must be one of: dev, development, staging, production, prod, test"
  }
}

variable "region" {
  description = "AWS region for the ECR repository"
  type        = string
}

#####################################################################
# Repository Configuration
#####################################################################

variable "repository_name" {
  description = <<-EOT
    Name of the ECR repository. If not provided, will be generated based on customer context.
    
    Naming conventions:
    - Use lowercase letters, numbers, hyphens, underscores, and forward slashes
    - Max 256 characters
    - Examples: "my-app", "backend/api", "frontend/web"
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.repository_name == null || can(regex("^[a-z0-9-_/]+$", var.repository_name))
    error_message = "repository_name must contain only lowercase letters, numbers, hyphens, underscores, and forward slashes"
  }
}

variable "image_tag_mutability" {
  description = <<-EOT
    Image tag mutability setting.
    
    - MUTABLE: Tags can be overwritten (default, flexible for development)
    - IMMUTABLE: Tags cannot be overwritten (recommended for production, ensures reproducibility)
    
    Best Practice: Use IMMUTABLE for production to prevent accidental overwrites
  EOT
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE"
  }
}

variable "force_delete" {
  description = <<-EOT
    Whether to allow deletion of the repository even if it contains images.
    
    WARNING: Setting to true will DELETE ALL IMAGES when repository is destroyed.
    Use with extreme caution in production environments.
    
    Recommended: false for production, true for dev/test
  EOT
  type        = bool
  default     = false
}

#####################################################################
# Image Scanning Configuration
#####################################################################

variable "scan_on_push" {
  description = <<-EOT
    Whether to automatically scan images on push.
    
    Highly recommended for security compliance.
    Scans for CVEs (Common Vulnerabilities and Exposures).
    
    Note: Enhanced scanning requires AWS Inspector to be enabled.
  EOT
  type        = bool
  default     = true
}

variable "image_scanning_configuration_type" {
  description = <<-EOT
    Type of image scanning to use.
    
    - BASIC: Free, scans for CVEs using Clair (open source)
    - ENHANCED: Paid, uses AWS Inspector for continuous scanning with OS and programming language vulnerabilities
    
    Enhanced scanning benefits:
    - Continuous monitoring (not just on push)
    - More comprehensive vulnerability database
    - SBOM (Software Bill of Materials) generation
    - Integration with AWS Security Hub
    
    Cost: Enhanced scanning is ~$0.09 per image per month
  EOT
  type        = string
  default     = "BASIC"

  validation {
    condition     = contains(["BASIC", "ENHANCED"], var.image_scanning_configuration_type)
    error_message = "image_scanning_configuration_type must be either BASIC or ENHANCED"
  }
}

variable "scan_frequency" {
  description = <<-EOT
    Scan frequency for enhanced scanning (only applies if image_scanning_configuration_type is ENHANCED).
    
    Options:
    - SCAN_ON_PUSH: Scan only when image is pushed
    - CONTINUOUS_SCAN: Continuously scan for new vulnerabilities (recommended)
    - MANUAL: Only scan when manually triggered
  EOT
  type        = string
  default     = "SCAN_ON_PUSH"

  validation {
    condition     = contains(["SCAN_ON_PUSH", "CONTINUOUS_SCAN", "MANUAL"], var.scan_frequency)
    error_message = "scan_frequency must be one of: SCAN_ON_PUSH, CONTINUOUS_SCAN, MANUAL"
  }
}

#####################################################################
# Encryption Configuration
#####################################################################

variable "encryption_type" {
  description = <<-EOT
    Encryption type for images at rest.
    
    - AES256: AWS managed encryption (default, free)
    - KMS: Customer managed KMS key (additional control and compliance)
    
    Use KMS for:
    - Compliance requirements (PCI-DSS, HIPAA, SOC2)
    - Cross-account access control
    - Audit trail of encryption key usage
    
    Cost: KMS is $1/month per key + API calls
  EOT
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be either AES256 or KMS"
  }
}

variable "kms_key_arn" {
  description = <<-EOT
    ARN of the KMS key to use for encryption (required if encryption_type is KMS).
    
    The KMS key must:
    - Be in the same region as the ECR repository
    - Grant ECR service permission to use it
    - Allow the IAM roles/users that pull images to decrypt
  EOT
  type        = string
  default     = null
}

#####################################################################
# Lifecycle Policy
#####################################################################

variable "enable_lifecycle_policy" {
  description = "Whether to enable lifecycle policy for automatic image cleanup"
  type        = bool
  default     = true
}

variable "lifecycle_policy_rules" {
  description = <<-EOT
    Custom lifecycle policy rules. If not provided, default rules will be applied based on environment.
    
    Default rules:
    - Production: Keep last 30 tagged images, expire untagged after 1 day
    - Staging: Keep last 10 tagged images, expire untagged after 1 day
    - Development: Keep last 5 tagged images, expire untagged after 1 day
    
    Example custom rule:
    {
      rulePriority = 1
      description  = "Keep last 10 production images"
      selection = {
        tagStatus     = "tagged"
        tagPrefixList = ["prod", "v"]
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }
  EOT
  type        = any
  default     = null
}

variable "max_image_count" {
  description = "Maximum number of tagged images to keep (used in default lifecycle policy)"
  type        = number
  default     = null
}

variable "untagged_image_retention_days" {
  description = "Number of days to keep untagged images before expiration (used in default lifecycle policy)"
  type        = number
  default     = 1

  validation {
    condition     = var.untagged_image_retention_days >= 1 && var.untagged_image_retention_days <= 365
    error_message = "untagged_image_retention_days must be between 1 and 365"
  }
}

#####################################################################
# Repository Policy (Access Control)
#####################################################################

variable "create_repository_policy" {
  description = "Whether to create a repository policy for cross-account or service access"
  type        = bool
  default     = false
}

variable "repository_policy_statements" {
  description = <<-EOT
    Custom repository policy statements for fine-grained access control.
    
    Example:
    [
      {
        sid    = "AllowEKSPull"
        effect = "Allow"
        principals = {
          service = ["eks.amazonaws.com"]
        }
        actions = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  EOT
  type        = any
  default     = []
}

variable "allow_cross_account_pull" {
  description = "Whether to allow cross-account pull access"
  type        = bool
  default     = false
}

variable "cross_account_ids" {
  description = "List of AWS account IDs allowed to pull images (if allow_cross_account_pull is true)"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.cross_account_ids : can(regex("^[0-9]{12}$", id))])
    error_message = "All cross_account_ids must be valid 12-digit AWS account IDs"
  }
}

variable "allow_lambda_pull" {
  description = "Whether to allow AWS Lambda to pull images from this repository"
  type        = bool
  default     = false
}

#####################################################################
# Replication Configuration
#####################################################################

variable "enable_replication" {
  description = <<-EOT
    Whether to enable cross-region or cross-account replication.
    
    Use cases:
    - Disaster recovery (replicate to DR region)
    - Multi-region deployments (reduce latency)
    - Cross-account sharing (dev/staging/prod separation)
  EOT
  type        = bool
  default     = false
}

variable "replication_destinations" {
  description = <<-EOT
    List of replication destinations.
    
    Example:
    [
      {
        region      = "us-west-2"
        registry_id = null  # Same account
      },
      {
        region      = "eu-west-1"
        registry_id = "123456789012"  # Different account
      }
    ]
  EOT
  type = list(object({
    region      = string
    registry_id = optional(string)
  }))
  default = []
}

#####################################################################
# Pull Through Cache Configuration
#####################################################################

variable "enable_pull_through_cache" {
  description = <<-EOT
    Whether to configure pull-through cache for public registries.
    
    Benefits:
    - Faster pulls (images cached in your ECR)
    - Avoid rate limits from public registries (Docker Hub, etc.)
    - Works even if public registry is unavailable
    
    Supported upstream registries:
    - Docker Hub
    - GitHub Container Registry (ghcr.io)
    - Kubernetes Registry (k8s.gcr.io)
    - Quay.io
  EOT
  type        = bool
  default     = false
}

variable "upstream_registry" {
  description = <<-EOT
    Upstream registry for pull-through cache.
    
    Options:
    - docker-hub
    - github-container-registry
    - kubernetes-registry
    - quay
  EOT
  type        = string
  default     = null

  validation {
    condition = var.upstream_registry == null || contains([
      "docker-hub",
      "github-container-registry", 
      "kubernetes-registry",
      "quay"
    ], var.upstream_registry)
    error_message = "upstream_registry must be one of: docker-hub, github-container-registry, kubernetes-registry, quay"
  }
}

#####################################################################
# Monitoring and Alerting
#####################################################################

variable "enable_cloudwatch_metrics" {
  description = "Whether to enable CloudWatch metrics for repository monitoring"
  type        = bool
  default     = true
}

variable "create_scan_findings_alarm" {
  description = "Whether to create CloudWatch alarm for critical/high severity scan findings"
  type        = bool
  default     = false
}

variable "scan_findings_alarm_threshold" {
  description = "Threshold for critical/high severity findings alarm"
  type        = number
  default     = 1

  validation {
    condition     = var.scan_findings_alarm_threshold >= 0
    error_message = "scan_findings_alarm_threshold must be non-negative"
  }
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  type        = string
  default     = null
}

#####################################################################
# Tags
#####################################################################

variable "tags" {
  description = "Additional tags to apply to ECR repository and related resources"
  type        = map(string)
  default     = {}
}

variable "enable_default_tags" {
  description = "Whether to apply default tags (customer, environment, architecture, etc.)"
  type        = bool
  default     = true
}
