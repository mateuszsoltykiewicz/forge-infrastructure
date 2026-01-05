# S3 Terraform Module

This module creates an AWS S3 bucket with comprehensive security, lifecycle management, encryption, and compliance features for the Forge platform.

## Features

- **Security by Default**:
  - Server-side encryption (SSE-S3 or SSE-KMS)
  - Public access blocking
  - Versioning support with MFA delete
  - Object Lock (WORM compliance)
- **Lifecycle Management**:
  - Automatic object transitions (Standard → IA → Glacier → Deep Archive)
  - Noncurrent version expiration
  - Incomplete multipart upload cleanup
  - Intelligent-Tiering for automatic cost optimization
- **Data Protection**:
  - Versioning with retention policies
  - Cross-region replication (CRR)
  - Object Lock for compliance (GOVERNANCE/COMPLIANCE modes)
- **Access Logging**: S3 access logs to audit bucket usage
- **CORS Configuration**: Support for web applications
- **Customer-Aware**: Automatic naming and tagging based on customer context

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        S3 Bucket                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Encryption: SSE-KMS (Customer Managed Key)              │   │
│  │  Versioning: Enabled                                      │   │
│  │  Public Access: Blocked                                   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Lifecycle Rules:                                         │   │
│  │  - Day 0:   S3 Standard                                  │   │
│  │  - Day 30:  S3 Standard-IA                               │   │
│  │  - Day 90:  S3 Glacier Instant Retrieval                 │   │
│  │  - Day 180: S3 Glacier Flexible Retrieval                │   │
│  │  - Day 365: S3 Glacier Deep Archive                      │   │
│  │  - Noncurrent versions: Delete after 90 days             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Replication (Optional):                                  │   │
│  │  - Destination: us-west-2 (DR region)                    │   │
│  │  - Encrypted replicas with replica KMS key               │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Usage Examples

### Example 1: Terraform State Bucket (Production)

```hcl
module "terraform_state_bucket" {
  source = "../../modules/storage/s3"

  # Customer Context (Shared Architecture)
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Bucket Configuration
  bucket_purpose = "terraform-state"
  force_destroy  = false  # Prevent accidental deletion

  # Versioning (Critical for state files)
  versioning_enabled   = true
  versioning_mfa_delete = false  # Enable if MFA is configured

  # Encryption (KMS for state files)
  encryption_enabled = true
  encryption_type    = "aws:kms"
  kms_key_id         = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  bucket_key_enabled = true

  # Public Access Block (Always enabled for state files)
  block_public_access = true

  # Lifecycle Rules
  lifecycle_rules = [
    {
      id      = "cleanup-old-versions"
      enabled = true
      
      noncurrent_version_expiration = {
        noncurrent_days = 90
      }
      
      abort_incomplete_multipart_upload_days = 7
    }
  ]

  # Logging
  logging_enabled       = true
  logging_target_bucket = "forge-production-logs-us-east-1"
  logging_target_prefix = "s3-access-logs/terraform-state/"

  # Replication to DR Region
  replication_enabled  = true
  replication_role_arn = "arn:aws:iam::123456789012:role/s3-replication-role"
  
  replication_rules = [
    {
      id       = "replicate-state-to-dr"
      status   = "Enabled"
      priority = 10
      
      destination = {
        bucket        = "arn:aws:s3:::forge-production-terraform-state-dr"
        storage_class = "STANDARD_IA"
        replica_kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/87654321-4321-4321-4321-210987654321"
      }
      
      source_selection_criteria = {
        sse_kms_encrypted_objects = {
          enabled = true
        }
      }
    }
  ]

  tags = {
    Critical    = "true"
    Compliance  = "SOC2"
    BackupRetention = "7-years"
  }
}
```

### Example 2: Application Data Bucket with Lifecycle

```hcl
module "application_data_bucket" {
  source = "../../modules/storage/s3"

  # Customer Context (Dedicated Architecture)
  customer_id       = "cust-123e4567-e89b-12d3-a456-426614174000"
  customer_name     = "acme-corp"
  architecture_type = "dedicated"
  plan_tier         = "enterprise"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Bucket Configuration
  bucket_purpose = "application-data"
  force_destroy  = false

  # Versioning
  versioning_enabled = true

  # Encryption
  encryption_enabled = true
  encryption_type    = "aws:kms"
  kms_key_id         = "arn:aws:kms:us-east-1:123456789012:key/abcdef12-3456-7890-abcd-ef1234567890"

  # Public Access Block
  block_public_access = true

  # Comprehensive Lifecycle Rules
  lifecycle_rules = [
    {
      id      = "transition-to-glacier"
      enabled = true
      prefix  = "data/"
      
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER_IR"
        },
        {
          days          = 180
          storage_class = "GLACIER"
        },
        {
          days          = 365
          storage_class = "DEEP_ARCHIVE"
        }
      ]
      
      noncurrent_version_transition = [
        {
          noncurrent_days = 30
          storage_class   = "STANDARD_IA"
        },
        {
          noncurrent_days = 90
          storage_class   = "GLACIER"
        }
      ]
      
      noncurrent_version_expiration = {
        noncurrent_days = 180
      }
      
      abort_incomplete_multipart_upload_days = 7
    },
    {
      id      = "expire-temp-files"
      enabled = true
      prefix  = "tmp/"
      
      expiration = {
        days = 7
      }
    }
  ]

  # Intelligent-Tiering (Alternative to manual lifecycle rules)
  intelligent_tiering_enabled            = false  # Using manual rules above
  intelligent_tiering_archive_days       = 90
  intelligent_tiering_deep_archive_days  = 180

  tags = {
    DataClassification = "Sensitive"
    RetentionPolicy    = "7-years"
  }
}
```

### Example 3: Static Website Hosting with CORS

```hcl
module "website_bucket" {
  source = "../../modules/storage/s3"

  # Customer Context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Bucket Configuration
  bucket_name    = "forge-production-website"
  bucket_purpose = "static-website"
  force_destroy  = false

  # Versioning
  versioning_enabled = true

  # Encryption
  encryption_enabled = true
  encryption_type    = "AES256"  # SSE-S3 for public content

  # Public Access (Allow for website hosting)
  block_public_access = false
  block_public_acls   = false
  block_public_policy = false

  # CORS Configuration
  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://forge.example.com", "https://www.forge.example.com"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3600
    }
  ]

  # Lifecycle (Cache invalidation)
  lifecycle_rules = [
    {
      id      = "cleanup-old-assets"
      enabled = true
      prefix  = "assets/"
      
      noncurrent_version_expiration = {
        noncurrent_days = 30
      }
    }
  ]

  tags = {
    Website = "forge-production"
    CDN     = "CloudFront"
  }
}
```

### Example 4: Backup Bucket with Object Lock (Compliance)

```hcl
module "backup_bucket" {
  source = "../../modules/storage/s3"

  # Customer Context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Bucket Configuration
  bucket_purpose = "database-backups"
  force_destroy  = false

  # Versioning (Required for Object Lock)
  versioning_enabled = true

  # Encryption
  encryption_enabled = true
  encryption_type    = "aws:kms"
  kms_key_id         = "arn:aws:kms:us-east-1:123456789012:key/backup-key-id"

  # Public Access Block
  block_public_access = true

  # Object Lock (WORM - Write Once Read Many)
  object_lock_enabled = true
  object_lock_configuration = {
    mode  = "COMPLIANCE"  # COMPLIANCE prevents deletion even by root
    days  = 2555          # 7 years retention
  }

  # Lifecycle Rules (Only for non-locked objects or after retention)
  lifecycle_rules = [
    {
      id      = "abort-multipart"
      enabled = true
      
      abort_incomplete_multipart_upload_days = 1
    }
  ]

  # Replication for disaster recovery
  replication_enabled  = true
  replication_role_arn = "arn:aws:iam::123456789012:role/backup-replication-role"
  
  replication_rules = [
    {
      id       = "replicate-backups"
      status   = "Enabled"
      priority = 1
      
      destination = {
        bucket        = "arn:aws:s3:::forge-production-backups-dr"
        storage_class = "GLACIER"
      }
    }
  ]

  tags = {
    Compliance      = "HIPAA"
    RetentionPeriod = "7-years"
    Critical        = "true"
  }
}
```

### Example 5: Logs Bucket with Intelligent-Tiering

```hcl
module "logs_bucket" {
  source = "../../modules/storage/s3"

  # Customer Context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Bucket Configuration
  bucket_purpose = "logs"
  force_destroy  = false

  # Versioning
  versioning_enabled = false  # Logs don't need versioning

  # Encryption
  encryption_enabled = true
  encryption_type    = "AES256"

  # Public Access Block
  block_public_access = true

  # Intelligent-Tiering (Automatic cost optimization)
  intelligent_tiering_enabled            = true
  intelligent_tiering_name               = "LogsAutoArchive"
  intelligent_tiering_archive_days       = 90   # Move to Archive Access after 90 days
  intelligent_tiering_deep_archive_days  = 180  # Move to Deep Archive after 180 days

  # Lifecycle Rules (Expiration)
  lifecycle_rules = [
    {
      id      = "expire-old-logs"
      enabled = true
      
      expiration = {
        days = 730  # 2 years
      }
      
      abort_incomplete_multipart_upload_days = 7
    }
  ]

  tags = {
    DataType     = "Logs"
    Retention    = "2-years"
    AutoArchive  = "true"
  }
}
```

## Bucket Naming Convention

The module automatically generates bucket names based on customer context:

### Shared Architecture
```
forge-{environment}-{purpose}-{region}

Examples:
- forge-production-terraform-state-us-east-1
- forge-production-logs-us-east-1
- forge-staging-application-data-us-west-2
```

### Dedicated Architecture
```
{customer_name}-{region}-{purpose}

Examples:
- acme-corp-us-east-1-application-data
- sanofi-eu-west-1-backups
- northrop-us-gov-west-1-sensitive-data
```

### Custom Names
You can override the automatic naming by providing `bucket_name`:

```hcl
bucket_name = "my-custom-bucket-name-12345"
```

## Lifecycle Management

### Storage Class Transitions

AWS S3 offers multiple storage classes for cost optimization:

| Storage Class | Use Case | Retrieval Time | Cost (per GB/month) |
|---------------|----------|----------------|---------------------|
| STANDARD | Frequently accessed | Immediate | $0.023 |
| STANDARD_IA | Infrequently accessed (>30 days) | Immediate | $0.0125 |
| GLACIER_IR | Long-term, instant retrieval | Immediate | $0.004 |
| GLACIER | Archive, occasional access | 1-5 minutes | $0.0036 |
| DEEP_ARCHIVE | Long-term archive (7-10 years) | 12 hours | $0.00099 |

### Intelligent-Tiering

Intelligent-Tiering automatically moves objects between access tiers based on usage:

```
┌─────────────────────────────────────────────────────────────┐
│  Object uploaded                                             │
│  ↓                                                            │
│  Frequent Access (monitored for 30 days)                     │
│  ↓ (no access for 30 days)                                   │
│  Infrequent Access (monitored for 90 days)                   │
│  ↓ (no access for 90 days - if enabled)                      │
│  Archive Access (monitored for 180 days)                     │
│  ↓ (no access for 180 days - if enabled)                     │
│  Deep Archive Access                                         │
└─────────────────────────────────────────────────────────────┘
```

**When to use Intelligent-Tiering**:
- Unknown or changing access patterns
- Large datasets with varying access frequency
- Automatic cost optimization without manual lifecycle rules

**Cost**: $0.0025 per 1,000 objects monitored

### Recommended Lifecycle Configurations

#### Application Data
```hcl
lifecycle_rules = [
  {
    id      = "optimize-costs"
    enabled = true
    
    transition = [
      { days = 30,  storage_class = "STANDARD_IA" },
      { days = 90,  storage_class = "GLACIER_IR" },
      { days = 365, storage_class = "GLACIER" }
    ]
    
    noncurrent_version_expiration = {
      noncurrent_days = 90
    }
  }
]
```

#### Logs (High Volume)
```hcl
intelligent_tiering_enabled            = true
intelligent_tiering_archive_days       = 90
intelligent_tiering_deep_archive_days  = 180

lifecycle_rules = [
  {
    id      = "expire-old-logs"
    enabled = true
    expiration = { days = 365 }
  }
]
```

#### Backups (Compliance)
```hcl
lifecycle_rules = [
  {
    id      = "archive-backups"
    enabled = true
    
    transition = [
      { days = 1,   storage_class = "GLACIER" },
      { days = 365, storage_class = "DEEP_ARCHIVE" }
    ]
    
    expiration = { days = 2555 }  # 7 years
  }
]
```

## Security

### Encryption at Rest

**SSE-S3 (AES256)**:
- AWS-managed keys
- No additional cost
- Suitable for public content

```hcl
encryption_enabled = true
encryption_type    = "AES256"
```

**SSE-KMS (aws:kms)**:
- Customer-managed keys
- Fine-grained access control
- Audit trail via CloudTrail
- Required for compliance (HIPAA, PCI-DSS)

```hcl
encryption_enabled = true
encryption_type    = "aws:kms"
kms_key_id         = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
bucket_key_enabled = true  # Reduces KMS API calls by 99%
```

**Bucket Keys**: Reduce KMS costs by up to 99% by using S3 Bucket Keys instead of individual object keys.

### Public Access Blocking

**Always enabled by default** for security:

```hcl
block_public_access = true  # Blocks all public access
```

Individual controls:
```hcl
block_public_acls       = true  # Block public ACLs
block_public_policy     = true  # Block public bucket policies
ignore_public_acls      = true  # Ignore existing public ACLs
restrict_public_buckets = true  # Restrict public bucket policies
```

### Versioning & MFA Delete

Versioning protects against accidental deletion:

```hcl
versioning_enabled   = true
versioning_mfa_delete = true  # Requires MFA to delete versions
```

**Note**: MFA delete requires AWS root account with MFA enabled.

### Object Lock (WORM)

Prevent object deletion/modification for compliance:

**COMPLIANCE Mode**:
- Cannot be overridden (even by root)
- Cannot be shortened
- For regulatory compliance (SEC 17a-4, HIPAA)

**GOVERNANCE Mode**:
- Can be overridden with special permissions
- For internal policies

```hcl
object_lock_enabled = true
object_lock_configuration = {
  mode  = "COMPLIANCE"
  days  = 2555  # 7 years
}
```

**Important**: Object Lock can only be enabled at bucket creation time.

## Cross-Region Replication

Replicate objects to another region for disaster recovery:

```hcl
replication_enabled  = true
replication_role_arn = "arn:aws:iam::123456789012:role/replication-role"

replication_rules = [
  {
    id       = "replicate-all"
    status   = "Enabled"
    priority = 10
    
    destination = {
      bucket        = "arn:aws:s3:::backup-bucket-us-west-2"
      storage_class = "GLACIER"
      replica_kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/replica-key"
    }
    
    source_selection_criteria = {
      sse_kms_encrypted_objects = {
        enabled = true
      }
    }
  }
]
```

**Requirements**:
1. Versioning must be enabled on both source and destination
2. IAM role with replication permissions
3. Destination bucket must exist

**Use Cases**:
- Disaster recovery
- Compliance requirements
- Data sovereignty (replicate to specific regions)

## Access Logging

Track all access requests to the bucket:

```hcl
logging_enabled       = true
logging_target_bucket = "forge-production-logs-us-east-1"
logging_target_prefix = "s3-access-logs/my-bucket/"
```

**Log Format**:
```
79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be 
forge-production-data [06/Feb/2024:00:00:38 +0000] 
192.0.2.3 79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be 
3E57427F3EXAMPLE REST.GET.VERSIONING - 
"GET /forge-production-data?versioning HTTP/1.1" 200 - 113 - 7 - "-" 
"S3Console/0.4" - s9lzHYrFp76ZVxRcpX9+5cjAnEH2ROuNkd2BHfIa6UkFVdtjf5mKR3/eTPFvsiP/XV/VLi31234= 
SigV2 ECDHE-RSA-AES128-GCM-SHA256 AuthHeader forge-production-data.s3.amazonaws.com 
TLSV1.1
```

## CORS Configuration

Enable cross-origin requests for web applications:

```hcl
cors_rules = [
  {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["https://app.example.com"]
    expose_headers  = ["ETag", "x-amz-meta-custom-header"]
    max_age_seconds = 3600
  }
]
```

## Cost Optimization

### 1. Use Intelligent-Tiering for Unknown Patterns
```hcl
intelligent_tiering_enabled = true
```

### 2. Lifecycle Transitions
```hcl
transition = [
  { days = 30,  storage_class = "STANDARD_IA" },   # Save ~45%
  { days = 90,  storage_class = "GLACIER_IR" },     # Save ~80%
  { days = 180, storage_class = "GLACIER" },        # Save ~85%
  { days = 365, storage_class = "DEEP_ARCHIVE" }    # Save ~95%
]
```

### 3. Enable S3 Bucket Keys
```hcl
bucket_key_enabled = true  # Reduces KMS costs by 99%
```

### 4. Expire Noncurrent Versions
```hcl
noncurrent_version_expiration = {
  noncurrent_days = 90
}
```

### 5. Clean Up Incomplete Multipart Uploads
```hcl
abort_incomplete_multipart_upload_days = 7
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| customer_id | UUID of the customer | string | n/a | yes |
| customer_name | Name of the customer | string | n/a | yes |
| architecture_type | Architecture type: shared, dedicated_single_tenant, dedicated_vpc | string | n/a | yes |
| plan_tier | Customer plan tier: basic, pro, enterprise, platform | string | n/a | yes |
| environment | Environment name | string | n/a | yes |
| region | AWS region | string | n/a | yes |
| bucket_name | S3 bucket name (auto-generated if empty) | string | "" | no |
| bucket_purpose | Purpose of the bucket | string | "general" | no |
| force_destroy | Allow destruction of non-empty bucket | bool | false | no |
| versioning_enabled | Enable versioning | bool | true | no |
| versioning_mfa_delete | Enable MFA delete | bool | false | no |
| encryption_enabled | Enable server-side encryption | bool | true | no |
| encryption_type | Encryption type: AES256 or aws:kms | string | "aws:kms" | no |
| kms_key_id | KMS key ID for encryption | string | null | no |
| bucket_key_enabled | Enable S3 Bucket Keys | bool | true | no |
| lifecycle_rules | List of lifecycle rules | list(object) | [] | no |
| block_public_access | Block all public access | bool | true | no |
| logging_enabled | Enable access logging | bool | false | no |
| logging_target_bucket | Target bucket for logs | string | "" | no |
| replication_enabled | Enable cross-region replication | bool | false | no |
| replication_rules | List of replication rules | list(object) | [] | no |
| object_lock_enabled | Enable Object Lock (WORM) | bool | false | no |
| object_lock_configuration | Object Lock configuration | object | null | no |
| cors_rules | List of CORS rules | list(object) | [] | no |
| intelligent_tiering_enabled | Enable Intelligent-Tiering | bool | false | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | The name of the bucket |
| bucket_arn | The ARN of the bucket |
| bucket_domain_name | The bucket domain name |
| bucket_regional_domain_name | The bucket region-specific domain name |
| bucket_region | The AWS region this bucket resides in |
| bucket_hosted_zone_id | The Route 53 Hosted Zone ID |
| versioning_enabled | Whether versioning is enabled |
| encryption_enabled | Whether encryption is enabled |
| encryption_type | The type of encryption used |
| kms_key_id | The KMS key ID used for encryption |
| public_access_blocked | Whether public access is blocked |
| replication_enabled | Whether replication is enabled |
| object_lock_enabled | Whether Object Lock is enabled |
| bucket_purpose | The purpose of this bucket |

## Troubleshooting

### Issue: Bucket name already exists

**Error**: `BucketAlreadyExists`

**Solution**: S3 bucket names are globally unique. Either:
1. Use auto-generated names (leave `bucket_name` empty)
2. Choose a unique name with a prefix/suffix

### Issue: Cannot enable Object Lock

**Error**: `InvalidBucketState`

**Solution**: Object Lock can only be enabled at bucket creation. You must:
1. Destroy the existing bucket (if safe)
2. Create a new bucket with `object_lock_enabled = true`

### Issue: KMS access denied

**Error**: `AccessDenied` when accessing encrypted objects

**Solution**: Ensure IAM policies grant:
```json
{
  "Effect": "Allow",
  "Action": [
    "kms:Decrypt",
    "kms:GenerateDataKey"
  ],
  "Resource": "arn:aws:kms:region:account:key/key-id"
}
```

### Issue: Replication not working

**Checklist**:
1. Versioning enabled on both source and destination? ✓
2. IAM role has correct trust policy? ✓
3. IAM role has permissions to read source and write destination? ✓
4. Destination bucket exists? ✓
5. Replication rule status is "Enabled"? ✓

## Best Practices

1. **Always enable encryption** (default: aws:kms)
2. **Always block public access** unless specifically needed
3. **Enable versioning** for critical data
4. **Use lifecycle rules** to optimize costs
5. **Enable access logging** for audit trails
6. **Use MFA delete** for compliance buckets
7. **Implement replication** for disaster recovery
8. **Use Object Lock** for regulatory compliance
9. **Clean up incomplete multipart uploads** (7 days)
10. **Use S3 Bucket Keys** to reduce KMS costs

## References

- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [S3 Storage Classes](https://aws.amazon.com/s3/storage-classes/)
- [S3 Intelligent-Tiering](https://aws.amazon.com/s3/storage-classes/intelligent-tiering/)
- [S3 Object Lock](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html)
- [S3 Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html)
- [Terraform AWS S3 Resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)

## License

This module is proprietary to Moai Engineering Forge platform.
