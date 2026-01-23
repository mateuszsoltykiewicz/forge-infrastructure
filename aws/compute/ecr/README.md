# ECR Module

Elastic Container Registry for storing Docker images with vulnerability scanning, encryption, and lifecycle policies.

## Features

- **Pattern A Compliance**: Region from parent module (`var.aws_region`)
- **Security**: Vulnerability scanning on push, AES256 or KMS encryption
- **Lifecycle Management**: Keep tagged images + last N untagged for rollback
- **IAM Access Control**: Fine-grained pull/push permissions
- **Cost Optimization**: Auto-delete old images

## Usage

```hcl
module "ecr_lambda_transformer" {
  source = "./compute/ecr"

  # Pattern A variables (region passed from parent)
  common_prefix = var.common_prefix
  common_tags   = var.common_tags
  environment   = var.environment
  aws_region    = var.aws_region  # Pattern A - region from parent

  # Repository configuration
  repository_name    = "lambda-log-transformer"
  repository_purpose = "Lambda Functions"

  # Security
  scan_on_push         = true
  encryption_type      = "AES256"  # Or "KMS" with kms_key_arn
  image_tag_mutability = "MUTABLE"

  # Lifecycle (keep tagged + last 5 untagged for rollback)
  keep_tagged_images   = 30
  keep_untagged_images = 5
  keep_tag_prefixes    = ["v", "release-", "prod-", "latest"]

  # IAM access (optional)
  allowed_principals      = []  # Empty = no repository policy
  allowed_push_principals = []
}
```

## Repository Naming Convention

Pattern A: `{common_prefix}-{repository_name}-{environment}`

Examples:
- `forge-lambda-log-transformer-production`
- `forge-api-backend-staging`
- `forge-frontend-dev`

## Docker Push Workflow

```bash
# 1. Get ECR login token
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 398456183268.dkr.ecr.eu-central-1.amazonaws.com

# 2. Build image
docker build --platform linux/amd64 -t lambda-log-transformer:latest .

# 3. Tag for ECR (use module output)
docker tag lambda-log-transformer:latest <repository_url>:latest

# 4. Push to ECR
docker push <repository_url>:latest
```

## Lifecycle Policy

**Rule 1**: Keep last 30 images with tag prefixes: `v`, `release-`, `prod-`, `staging-`, `latest`
**Rule 2**: Keep last 5 untagged images (for rollback safety)

This allows:
- Production releases: `prod-1.2.3`, `release-2024-01-17`
- Development: `latest`, `v0.0.1-alpha`
- Rollback: Last 5 untagged images available

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| common_prefix | Pattern A prefix | `string` | - | yes |
| common_tags | Pattern A tags | `map(string)` | - | yes |
| environment | Environment (dev/staging/production) | `string` | - | yes |
| aws_region | AWS region (Pattern A from parent) | `string` | - | yes |
| repository_name | Repository name (will be prefixed) | `string` | - | yes |
| repository_purpose | Purpose description | `string` | `"Container Images"` | no |
| scan_on_push | Enable vulnerability scanning | `bool` | `true` | no |
| encryption_type | Encryption (AES256 or KMS) | `string` | `"AES256"` | no |
| kms_key_arn | KMS key ARN (if encryption_type=KMS) | `string` | `null` | no |
| keep_tagged_images | Number of tagged images to keep | `number` | `30` | no |
| keep_untagged_images | Number of untagged images to keep | `number` | `5` | no |

## Outputs

| Name | Description |
|------|-------------|
| repository_url | Full ECR URL for docker push |
| repository_uri_with_tag | URI with `:latest` tag (ready for Lambda) |
| repository_arn | Repository ARN |
| repository_name | Repository name |
| registry_id | AWS account ID |

## Vulnerability Scanning

Enabled by default (`scan_on_push = true`). Scan results available in:
- ECR Console → Repository → Images → Scan status
- AWS Security Hub (if integrated)
- EventBridge events for automated alerting

## Cost Optimization

**Storage**: $0.10/GB/month
- Lifecycle policy auto-deletes old images
- Example: 30 tagged + 5 untagged × 500MB = **17.5GB** = **$1.75/month**

**Data Transfer**:
- Same region (ECR → Lambda): **Free**
- Cross-region: $0.02/GB

## Dependencies

None - standalone module

## License

Proprietary - Forge Platform
