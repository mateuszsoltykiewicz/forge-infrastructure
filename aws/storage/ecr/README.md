# ECR (Elastic Container Registry) Module

Terraform module for creating and managing AWS ECR repositories with comprehensive security scanning, lifecycle policies, and cross-account access control.

## Features

- **Image Scanning**: Basic (free) or Enhanced (AWS Inspector) vulnerability scanning
- **Immutable Tags**: Prevent accidental image overwrites in production
- **KMS Encryption**: Customer-managed encryption keys for compliance
- **Lifecycle Policies**: Automatic cleanup of old images for cost optimization
- **Cross-Account Access**: Share images across AWS accounts
- **Replication**: Multi-region and cross-account replication
- **Pull-Through Cache**: Cache public registry images (Docker Hub, ghcr.io, etc.)
- **CloudWatch Monitoring**: Metrics and alarms for security findings
- **Kubernetes Integration**: Ready-to-use ImagePullSecrets

## Usage

### Example 1: Basic Development Repository

```hcl
module "dev_ecr" {
  source = "../../modules/storage/ecr"

  # Customer Context
  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "basic"
  environment       = "dev"
  region            = "us-east-1"

  # Repository Configuration
  repository_name       = "my-app"
  image_tag_mutability  = "MUTABLE"  # Allow tag overwrites in dev
  force_delete          = true       # Allow deletion with images

  # Basic scanning (free)
  scan_on_push                      = true
  image_scanning_configuration_type = "BASIC"

  # AWS managed encryption (free)
  encryption_type = "AES256"

  # Lifecycle policy - keep last 5 images
  enable_lifecycle_policy       = true
  max_image_count               = 5
  untagged_image_retention_days = 1

  tags = {
    Application = "my-app"
    CostCenter  = "development"
  }
}

# Output repository URL
output "repository_url" {
  value = module.dev_ecr.repository_url
}
```

### Example 2: Production Repository with Enhanced Security

```hcl
module "prod_ecr" {
  source = "../../modules/storage/ecr"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "enterprise"
  environment       = "production"
  region            = "us-east-1"

  repository_name      = "production/api"
  image_tag_mutability = "IMMUTABLE"  # Prevent tag overwrites
  force_delete         = false         # Prevent accidental deletion

  # Enhanced scanning with continuous monitoring
  scan_on_push                      = true
  image_scanning_configuration_type = "ENHANCED"
  scan_frequency                    = "CONTINUOUS_SCAN"

  # KMS encryption for compliance
  encryption_type = "KMS"
  kms_key_arn     = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Production lifecycle - keep last 30 images
  enable_lifecycle_policy       = true
  max_image_count               = 30
  untagged_image_retention_days = 1

  # CloudWatch alarm for vulnerabilities
  create_scan_findings_alarm    = true
  scan_findings_alarm_threshold = 1
  alarm_sns_topic_arn           = "arn:aws:sns:us-east-1:123456789012:security-alerts"

  tags = {
    Application = "api"
    Compliance  = "pci-dss"
    Critical    = "true"
  }
}
```

### Example 3: Cross-Account ECR Sharing

```hcl
# Central ECR repository (shared account)
module "shared_ecr" {
  source = "../../modules/storage/ecr"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "pro"
  environment       = "shared"
  region            = "us-east-1"

  repository_name      = "shared/base-images"
  image_tag_mutability = "IMMUTABLE"

  # Enhanced scanning
  scan_on_push                      = true
  image_scanning_configuration_type = "ENHANCED"

  # KMS encryption
  encryption_type = "KMS"
  kms_key_arn     = var.kms_key_arn

  # Allow pull access from dev, staging, and prod accounts
  create_repository_policy = true
  allow_cross_account_pull = true
  cross_account_ids = [
    "111111111111",  # Development account
    "222222222222",  # Staging account
    "333333333333"   # Production account
  ]

  tags = {
    Purpose = "shared-base-images"
  }
}
```

### Example 4: Lambda Container Images

```hcl
module "lambda_ecr" {
  source = "../../modules/storage/ecr"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "pro"
  environment       = "production"
  region            = "us-east-1"

  repository_name      = "lambda/my-function"
  image_tag_mutability = "IMMUTABLE"

  # Scanning
  scan_on_push                      = true
  image_scanning_configuration_type = "ENHANCED"

  # Allow Lambda service to pull images
  allow_lambda_pull = true

  # Lifecycle - Lambda functions don't need many versions
  enable_lifecycle_policy       = true
  max_image_count               = 10
  untagged_image_retention_days = 1

  tags = {
    Service = "lambda"
  }
}

# Lambda function using ECR image
resource "aws_lambda_function" "main" {
  function_name = "my-function"
  role          = aws_iam_role.lambda.arn
  package_type  = "Image"
  image_uri     = "${module.lambda_ecr.repository_url}:latest"
  
  # ... other Lambda configuration ...
}
```

### Example 5: Multi-Region Replication

```hcl
# Primary repository in us-east-1
module "primary_ecr" {
  source = "../../modules/storage/ecr"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "enterprise"
  environment       = "production"
  region            = "us-east-1"

  repository_name      = "production/web-app"
  image_tag_mutability = "IMMUTABLE"

  # Enhanced scanning
  scan_on_push                      = true
  image_scanning_configuration_type = "ENHANCED"

  # KMS encryption
  encryption_type = "KMS"
  kms_key_arn     = var.kms_key_us_east_1

  # Replicate to DR region and EU region
  enable_replication = true
  replication_destinations = [
    {
      region      = "us-west-2"   # DR region
      registry_id = null           # Same account
    },
    {
      region      = "eu-west-1"    # EU region
      registry_id = null           # Same account
    }
  ]

  tags = {
    MultiRegion = "true"
  }
}
```

### Example 6: Pull-Through Cache for Docker Hub

```hcl
module "docker_hub_cache" {
  source = "../../modules/storage/ecr"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "pro"
  environment       = "production"
  region            = "us-east-1"

  repository_name      = "docker-hub-cache"
  image_tag_mutability = "IMMUTABLE"

  # Enable pull-through cache for Docker Hub
  enable_pull_through_cache = true
  upstream_registry         = "docker-hub"

  # Scanning cached images
  scan_on_push                      = true
  image_scanning_configuration_type = "BASIC"

  # Lifecycle - clean up cached images
  enable_lifecycle_policy       = true
  max_image_count               = 50
  untagged_image_retention_days = 7

  tags = {
    Purpose = "docker-hub-cache"
  }
}

# Usage in Kubernetes/ECS:
# Instead of: docker.io/nginx:latest
# Use: ${module.docker_hub_cache.repository_url}/nginx:latest
```

### Example 7: EKS Integration with ImagePullSecrets

```hcl
module "eks_ecr" {
  source = "../../modules/storage/ecr"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "enterprise"
  environment       = "production"
  region            = "us-east-1"

  repository_name      = "eks/microservices"
  image_tag_mutability = "IMMUTABLE"

  # Enhanced scanning
  scan_on_push                      = true
  image_scanning_configuration_type = "ENHANCED"
  scan_frequency                    = "CONTINUOUS_SCAN"

  # KMS encryption
  encryption_type = "KMS"
  kms_key_arn     = var.kms_key_arn

  # Production lifecycle
  enable_lifecycle_policy       = true
  max_image_count               = 30
  untagged_image_retention_days = 1

  tags = {
    Platform = "eks"
  }
}

# Create Kubernetes secret for image pulling
resource "kubernetes_secret" "ecr_credentials" {
  metadata {
    name      = "ecr-registry-credentials"
    namespace = "default"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${module.eks_ecr.registry_id}.dkr.ecr.${var.region}.amazonaws.com" = {
          auth = base64encode("AWS:${data.aws_ecr_authorization_token.token.password}")
        }
      }
    })
  }
}

# Use in pod spec:
# imagePullSecrets:
# - name: ecr-registry-credentials
```

### Example 8: Custom Lifecycle Policy

```hcl
module "custom_lifecycle_ecr" {
  source = "../../modules/storage/ecr"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "pro"
  environment       = "production"
  region            = "us-east-1"

  repository_name = "custom-app"

  # Custom lifecycle policy
  enable_lifecycle_policy = true
  lifecycle_policy_rules = {
    rules = [
      # Keep all production tags indefinitely
      {
        rulePriority = 1
        description  = "Keep all production tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod-", "release-"]
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = 9999
        }
        action = {
          type = "expire"
        }
      },
      # Keep last 10 dev/staging images
      {
        rulePriority = 2
        description  = "Keep last 10 dev/staging images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev-", "staging-"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      # Expire untagged images after 1 day
      {
        rulePriority = 3
        description  = "Expire untagged images"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  }
}
```

### Example 9: CodePipeline Integration

```hcl
module "pipeline_ecr" {
  source = "../../modules/storage/ecr"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "pro"
  environment       = "production"
  region            = "us-east-1"

  repository_name      = "cicd/application"
  image_tag_mutability = "IMMUTABLE"

  # Scanning
  scan_on_push                      = true
  image_scanning_configuration_type = "ENHANCED"

  # Lifecycle
  enable_lifecycle_policy       = true
  max_image_count               = 20
  untagged_image_retention_days = 1

  # Custom repository policy for CodeBuild
  create_repository_policy = true
  repository_policy_statements = [
    {
      sid    = "AllowCodeBuildAccess"
      effect = "Allow"
      principals = {
        service = ["codebuild.amazonaws.com"]
      }
      actions = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
    }
  ]

  tags = {
    Pipeline = "codepipeline"
  }
}

# Use in CodeBuild buildspec.yml:
# phases:
#   build:
#     commands:
#       - docker build -t ${module.pipeline_ecr.repository_url}:$CODEBUILD_RESOLVED_SOURCE_VERSION .
#       - docker push ${module.pipeline_ecr.repository_url}:$CODEBUILD_RESOLVED_SOURCE_VERSION
```

### Example 10: Multi-Environment Setup

```hcl
# Development
module "ecr_dev" {
  source = "../../modules/storage/ecr"

  customer_id   = "acme-corp"
  customer_name = "ACME Corporation"
  environment   = "dev"
  region        = "us-east-1"

  repository_name       = "my-app"
  image_tag_mutability  = "MUTABLE"
  force_delete          = true

  scan_on_push                      = true
  image_scanning_configuration_type = "BASIC"
  encryption_type                   = "AES256"

  max_image_count               = 5
  untagged_image_retention_days = 1
}

# Staging
module "ecr_staging" {
  source = "../../modules/storage/ecr"

  customer_id   = "acme-corp"
  customer_name = "ACME Corporation"
  environment   = "staging"
  region        = "us-east-1"

  repository_name       = "my-app"
  image_tag_mutability  = "IMMUTABLE"
  force_delete          = false

  scan_on_push                      = true
  image_scanning_configuration_type = "ENHANCED"
  scan_frequency                    = "SCAN_ON_PUSH"
  encryption_type                   = "KMS"
  kms_key_arn                       = var.kms_key_arn

  max_image_count               = 10
  untagged_image_retention_days = 1
}

# Production
module "ecr_prod" {
  source = "../../modules/storage/ecr"

  customer_id   = "acme-corp"
  customer_name = "ACME Corporation"
  environment   = "production"
  region        = "us-east-1"

  repository_name       = "my-app"
  image_tag_mutability  = "IMMUTABLE"
  force_delete          = false

  scan_on_push                      = true
  image_scanning_configuration_type = "ENHANCED"
  scan_frequency                    = "CONTINUOUS_SCAN"
  encryption_type                   = "KMS"
  kms_key_arn                       = var.kms_key_arn

  create_scan_findings_alarm    = true
  scan_findings_alarm_threshold = 1
  alarm_sns_topic_arn           = var.sns_topic_arn

  enable_replication = true
  replication_destinations = [
    { region = "us-west-2", registry_id = null }  # DR region
  ]

  max_image_count               = 30
  untagged_image_retention_days = 1
}
```

## Image Scanning

### Basic vs Enhanced Scanning

| Feature | Basic (Free) | Enhanced (~$0.09/image/month) |
|---------|-------------|-------------------------------|
| **Scan Trigger** | On push only | On push + continuous |
| **Vulnerability Database** | Clair (open source) | AWS Inspector (comprehensive) |
| **OS Package Scanning** | ✅ Yes | ✅ Yes |
| **Programming Language Scanning** | ❌ No | ✅ Yes (Python, Java, Node.js, etc.) |
| **SBOM Generation** | ❌ No | ✅ Yes |
| **Security Hub Integration** | ❌ No | ✅ Yes |
| **Continuous Monitoring** | ❌ No | ✅ Yes |
| **Compliance** | Basic | PCI-DSS, HIPAA, SOC2 |

### Scan Frequency Options

- **SCAN_ON_PUSH**: Scan only when image is pushed (cost-effective)
- **CONTINUOUS_SCAN**: Continuously scan for new vulnerabilities (recommended for production)
- **MANUAL**: Only scan when manually triggered

### Interpreting Scan Results

```bash
# View scan findings
aws ecr describe-image-scan-findings \
  --repository-name my-app \
  --image-id imageTag=latest \
  --region us-east-1

# Severity levels:
# - CRITICAL: Immediate action required
# - HIGH: Should be fixed soon
# - MEDIUM: Should be reviewed
# - LOW: Optional fix
# - INFORMATIONAL: FYI only
```

## Lifecycle Policies

### Default Policies by Environment

| Environment | Tagged Images | Untagged Images |
|-------------|--------------|-----------------|
| **Development** | Keep last 5 | Expire after 1 day |
| **Staging** | Keep last 10 | Expire after 1 day |
| **Production** | Keep last 30 | Expire after 1 day |

### Cost Optimization Strategies

1. **Aggressive Cleanup (Development)**
   ```hcl
   max_image_count               = 3
   untagged_image_retention_days = 1
   ```

2. **Balanced (Staging)**
   ```hcl
   max_image_count               = 10
   untagged_image_retention_days = 1
   ```

3. **Conservative (Production)**
   ```hcl
   max_image_count               = 30
   untagged_image_retention_days = 1
   ```

4. **Custom by Tag Prefix**
   - Keep all `prod-*` tags
   - Keep last 10 `staging-*` tags
   - Keep last 5 `dev-*` tags
   - Expire `branch-*` tags after 7 days

## Cross-Account Access

### Scenario 1: Shared Registry Account

```
┌─────────────────┐
│ Registry Account│
│  (123456789012) │
│                 │
│  ECR Repository │
│  - shared/base  │
└────────┬────────┘
         │
    ┌────┴────┬────────┐
    │         │        │
┌───▼───┐ ┌──▼───┐ ┌──▼────┐
│  Dev  │ │Staging│ │  Prod  │
│Account│ │Account│ │Account │
└───────┘ └──────┘ └────────┘
```

**Configuration:**
```hcl
allow_cross_account_pull = true
cross_account_ids = [
  "111111111111",  # Dev
  "222222222222",  # Staging
  "333333333333"   # Prod
]
```

### Scenario 2: Pull from Another Account

In the consuming account, use IAM role with this policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": "arn:aws:ecr:us-east-1:123456789012:repository/shared/base"
    }
  ]
}
```

## Docker Workflow

### Basic Workflow

```bash
# 1. Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com

# 2. Build image
docker build -t my-app:v1.0.0 .

# 3. Tag image for ECR
docker tag my-app:v1.0.0 \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:v1.0.0

# 4. Push to ECR
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:v1.0.0

# 5. Pull image (on another machine)
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:v1.0.0
```

### Multi-Architecture Images

```bash
# Build for multiple architectures
docker buildx build --platform linux/amd64,linux/arm64 \
  -t 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:v1.0.0 \
  --push .
```

### Image Signing (Cosign)

```bash
# Sign image with Cosign
cosign sign --key cosign.key \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:v1.0.0

# Verify signature
cosign verify --key cosign.pub \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:v1.0.0
```

## Kubernetes Integration

### ImagePullSecret Creation

```bash
# Create Kubernetes secret
kubectl create secret docker-registry ecr-credentials \
  --docker-server=123456789012.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  --namespace=default
```

### Pod Specification

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: app
    image: 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:v1.0.0
  imagePullSecrets:
  - name: ecr-credentials
```

### Automatic Secret Refresh

Since ECR tokens expire after 12 hours, use a CronJob to refresh:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: ecr-credential-refresh
spec:
  schedule: "0 */6 * * *"  # Every 6 hours
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: ecr-refresh-sa
          containers:
          - name: refresh
            image: amazon/aws-cli:latest
            command:
            - /bin/sh
            - -c
            - |
              kubectl delete secret ecr-credentials --ignore-not-found
              kubectl create secret docker-registry ecr-credentials \
                --docker-server=123456789012.dkr.ecr.us-east-1.amazonaws.com \
                --docker-username=AWS \
                --docker-password=$(aws ecr get-login-password --region us-east-1)
          restartPolicy: OnFailure
```

## Cost Optimization

### Storage Costs

| Storage Amount | Monthly Cost |
|----------------|-------------|
| **First 500 MB** | Free (AWS Free Tier) |
| **Next 10 GB** | $1.00 |
| **Next 50 GB** | $5.00 |
| **Next 500 GB** | $50.00 |
| **1 TB** | $100.00 |

**Formula**: $0.10 per GB per month

### Scanning Costs

| Scan Type | Cost |
|-----------|------|
| **Basic** | Free |
| **Enhanced** | ~$0.09 per image per month |

### Example Monthly Costs

| Scenario | Images | Storage | Scan Type | KMS | Total |
|----------|--------|---------|-----------|-----|-------|
| **Small Dev** | 10 | 5 GB | Basic | No | ~$0.50 |
| **Medium Staging** | 50 | 50 GB | Enhanced | Yes | ~$10.50 |
| **Large Production** | 200 | 500 GB | Enhanced | Yes | ~$69.00 |

### Optimization Tips

1. **Use Lifecycle Policies**
   - Automatically delete old images
   - Keep only necessary tagged images

2. **Optimize Image Size**
   - Use multi-stage builds
   - Use Alpine or distroless base images
   - Remove build dependencies

3. **Consolidate Repositories**
   - Use namespaces: `app/frontend`, `app/backend`
   - Share base images across teams

4. **Use Basic Scanning for Dev**
   - Enhanced scanning only for production
   - Save ~$0.09 per dev image per month

## Security Best Practices

1. **Immutable Tags in Production**
   ```hcl
   image_tag_mutability = "IMMUTABLE"
   ```

2. **Enable Image Scanning**
   ```hcl
   scan_on_push = true
   image_scanning_configuration_type = "ENHANCED"  # Production
   ```

3. **Use KMS Encryption**
   ```hcl
   encryption_type = "KMS"
   kms_key_arn     = var.kms_key_arn
   ```

4. **Lifecycle Policies**
   ```hcl
   enable_lifecycle_policy = true
   ```

5. **Least Privilege Access**
   - Use repository policies for fine-grained control
   - Separate pull and push permissions

6. **Monitor Scan Findings**
   ```hcl
   create_scan_findings_alarm = true
   ```

7. **Prevent Deletion**
   ```hcl
   force_delete = false  # Production
   ```

8. **Use Replication for DR**
   ```hcl
   enable_replication = true
   ```

## Troubleshooting

### Login Failed

```bash
# Error: "no basic auth credentials"
# Solution: Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com
```

### Push Denied

```bash
# Error: "denied: Your authorization token has expired"
# Solution: Token expires after 12 hours, re-login
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com
```

### Image Not Found

```bash
# Error: "repository does not exist"
# Solution: Verify repository name
aws ecr describe-repositories --region us-east-1
```

### Scan Failed

```bash
# Check scan status
aws ecr describe-image-scan-findings \
  --repository-name my-app \
  --image-id imageTag=latest

# Common causes:
# - Enhanced scanning not enabled
# - AWS Inspector not configured
# - Image too large (>10 GB not supported)
```

### Kubernetes Pull Failed

```bash
# Error: "ErrImagePull" or "ImagePullBackOff"

# 1. Check secret exists
kubectl get secret ecr-credentials

# 2. Check secret is valid (token expires after 12 hours)
kubectl delete secret ecr-credentials
kubectl create secret docker-registry ecr-credentials \
  --docker-server=123456789012.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1)

# 3. Check IAM permissions
# Node IAM role needs: ecr:GetAuthorizationToken, ecr:BatchCheckLayerAvailability, ecr:GetDownloadUrlForLayer, ecr:BatchGetImage
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 6.9.0 |
| null | >= 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| customer_id | Unique identifier for the customer | `string` | n/a | yes |
| customer_name | Human-readable name of the customer | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| region | AWS region | `string` | n/a | yes |
| architecture_type | Architecture type | `string` | `"forge"` | no |
| plan_tier | Service plan tier | `string` | `"basic"` | no |
| repository_name | ECR repository name | `string` | `null` | no |
| image_tag_mutability | Tag mutability (MUTABLE/IMMUTABLE) | `string` | `"MUTABLE"` | no |
| force_delete | Allow deletion with images | `bool` | `false` | no |
| scan_on_push | Scan images on push | `bool` | `true` | no |
| image_scanning_configuration_type | Scan type (BASIC/ENHANCED) | `string` | `"BASIC"` | no |
| scan_frequency | Scan frequency for enhanced scanning | `string` | `"SCAN_ON_PUSH"` | no |
| encryption_type | Encryption type (AES256/KMS) | `string` | `"AES256"` | no |
| kms_key_arn | KMS key ARN | `string` | `null` | no |
| enable_lifecycle_policy | Enable lifecycle policy | `bool` | `true` | no |
| max_image_count | Max tagged images to keep | `number` | `null` | no |
| untagged_image_retention_days | Days to keep untagged images | `number` | `1` | no |
| allow_cross_account_pull | Allow cross-account pull | `bool` | `false` | no |
| cross_account_ids | Cross-account IDs | `list(string)` | `[]` | no |
| allow_lambda_pull | Allow Lambda pull | `bool` | `false` | no |
| enable_replication | Enable replication | `bool` | `false` | no |
| replication_destinations | Replication destinations | `list(object)` | `[]` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| repository_name | Repository name |
| repository_arn | Repository ARN |
| repository_url | Repository URL |
| registry_id | Registry ID |
| docker_commands | Useful Docker commands |
| push_policy_json | IAM policy for push access |
| pull_policy_json | IAM policy for pull access |
| kubernetes_image_pull_secret | Kubernetes ImagePullSecret config |
| repository_summary | Complete summary |

## Authors

MOAI Engineering Team

## License

Proprietary - MOAI Platform
