# KMS Terraform Module

This module creates an AWS KMS (Key Management Service) customer managed key with flexible key policies, automatic rotation, aliases, and grants for the Forge platform.

## Features

- **Flexible Key Types**:
  - Symmetric keys (AES-256) for encryption/decryption
  - Asymmetric keys (RSA, ECC) for signing/verification
  - Multi-region keys for global applications
- **Automatic Key Rotation**: Annual rotation with configurable period (90-2560 days)
- **Key Policies**:
  - Default IAM root access policy
  - Key administrators with full management permissions
  - Key users for cryptographic operations
  - AWS service principals (S3, RDS, EBS, etc.)
  - Custom key policies with conditions
- **Aliases**: Human-readable key identifiers
- **Grants**: Programmatic delegation of key permissions
- **Customer-Aware**: Automatic naming and tagging based on customer context
- **Security**: Configurable deletion window (7-30 days)

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      KMS Customer Managed Key                 │
│                                                                │
│  Key Policy                                                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Root Account:                                         │  │
│  │  - Full KMS permissions (kms:*)                        │  │
│  │                                                          │  │
│  │  Key Administrators:                                    │  │
│  │  - Create, Describe, Enable, Disable, Update, Delete  │  │
│  │  - Schedule/Cancel key deletion                        │  │
│  │  - Tag/Untag resources                                 │  │
│  │                                                          │  │
│  │  Key Users:                                             │  │
│  │  - Encrypt, Decrypt, ReEncrypt, GenerateDataKey       │  │
│  │  - CreateGrant (for AWS resource integration)          │  │
│  │                                                          │  │
│  │  AWS Services (S3, RDS, EBS, etc.):                    │  │
│  │  - Encrypt, Decrypt via service endpoint               │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                                │
│  Alias: alias/forge-production-rds                            │
│  Rotation: Enabled (365 days)                                 │
│  Multi-Region: Optional                                       │
└──────────────────────────────────────────────────────────────┘
```

## Usage Examples

### Example 1: RDS Database Encryption Key

```hcl
module "rds_kms_key" {
  source = "../../modules/security/kms"

  # Customer Context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Key Configuration
  key_description = "KMS key for RDS database encryption"
  key_purpose     = "rds"
  key_usage       = "ENCRYPT_DECRYPT"
  
  # Automatic rotation (enabled by default for symmetric keys)
  enable_key_rotation     = true
  rotation_period_in_days = 365  # Annual rotation

  # Deletion protection
  deletion_window_in_days = 30

  # Key Policy - Root access + RDS service
  enable_default_policy = true
  
  key_service_users = [
    "rds.amazonaws.com"
  ]

  # Alias
  create_alias = true  # Creates alias/forge-production-rds

  tags = {
    Purpose    = "RDS Encryption"
    Compliance = "SOC2"
  }
}
```

### Example 2: S3 Bucket Encryption Key with Admin and User Roles

```hcl
module "s3_kms_key" {
  source = "../../modules/security/kms"

  # Customer Context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Key Configuration
  key_description = "KMS key for S3 bucket encryption"
  key_purpose     = "s3"
  
  # Key Policy - Administrators and users
  enable_default_policy = true
  
  key_administrators = [
    "arn:aws:iam::123456789012:role/InfrastructureAdmin",
    "arn:aws:iam::123456789012:user/ops-team"
  ]
  
  key_users = [
    "arn:aws:iam::123456789012:role/ApplicationRole",
    "arn:aws:iam::123456789012:role/forge-production-eks-pod-s3-access"
  ]
  
  key_service_users = [
    "s3.amazonaws.com"
  ]

  # Alias
  create_alias = true

  tags = {
    Purpose = "S3 Encryption"
  }
}
```

### Example 3: EKS Secrets Encryption Key

```hcl
module "eks_secrets_kms_key" {
  source = "../../modules/security/kms"

  # Customer Context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Key Configuration
  key_description = "KMS key for EKS secrets encryption"
  key_purpose     = "eks-secrets"
  
  # Automatic rotation
  enable_key_rotation     = true
  rotation_period_in_days = 180  # Rotate every 6 months

  # Key Policy - EKS cluster role
  enable_default_policy = true
  
  key_users = [
    "arn:aws:iam::123456789012:role/forge-production-eks-cluster"
  ]

  # Alias
  create_alias = true

  tags = {
    Purpose = "EKS Secrets Encryption"
    Cluster = "forge-production-eks"
  }
}
```

### Example 4: Multi-Region Key for Global Application

```hcl
module "global_kms_key" {
  source = "../../modules/security/kms"

  # Customer Context
  customer_id       = "cust-123e4567-e89b-12d3-a456-426614174000"
  customer_name     = "acme-corp"
  architecture_type = "dedicated"
  plan_tier         = "enterprise"

  # Environment
  environment = "production"
  region      = "us-east-1"  # Primary region

  # Key Configuration
  key_description = "Multi-region KMS key for global data encryption"
  key_purpose     = "global-data"
  multi_region    = true  # Enable multi-region key
  
  # Automatic rotation
  enable_key_rotation     = true
  rotation_period_in_days = 365

  # Key Policy
  enable_default_policy = true
  
  key_users = [
    "arn:aws:iam::123456789012:role/acme-corp-application"
  ]

  # Alias
  create_alias = true

  tags = {
    Purpose      = "Global Data Encryption"
    MultiRegion  = "true"
    ReplicaRegions = "us-west-2,eu-west-1,ap-southeast-1"
  }
}

# Replica keys in other regions
module "global_kms_key_us_west_2" {
  source = "../../modules/security/kms"
  providers = {
    aws = aws.us-west-2
  }

  # ... same configuration with different region
  region = "us-west-2"
  
  # Reference the primary key for replication
  # (handled outside module scope)
}
```

### Example 5: Asymmetric Key for Digital Signatures

```hcl
module "signing_kms_key" {
  source = "../../modules/security/kms"

  # Customer Context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Key Configuration - Asymmetric for signing
  key_description          = "KMS key for digital signatures"
  key_purpose              = "signing"
  key_usage                = "SIGN_VERIFY"
  customer_master_key_spec = "RSA_2048"
  
  # Automatic rotation not supported for asymmetric keys
  enable_key_rotation = false

  # Key Policy
  enable_default_policy = true
  
  key_users = [
    "arn:aws:iam::123456789012:role/CodeSigningRole"
  ]

  # Alias
  create_alias = true

  tags = {
    Purpose = "Code Signing"
  }
}
```

### Example 6: Custom Key Policy with Conditions

```hcl
module "custom_policy_kms_key" {
  source = "../../modules/security/kms"

  # Customer Context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Key Configuration
  key_description = "KMS key with custom policy and conditions"
  key_purpose     = "custom-policy"

  # Custom Key Policy (full control)
  custom_key_policy = jsonencode({
    Version = "2012-10-17"
    Id      = "custom-key-policy"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow use from specific VPC"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:role/ApplicationRole"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceVpc" = "vpc-0123456789abcdef0"
          }
        }
      },
      {
        Sid    = "Allow use only during business hours"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:role/DataAnalystRole"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          DateGreaterThan = {
            "aws:CurrentTime" = "2024-01-01T09:00:00Z"
          }
          DateLessThan = {
            "aws:CurrentTime" = "2024-01-01T17:00:00Z"
          }
        }
      }
    ]
  })

  # Alias
  create_alias = true

  tags = {
    Purpose = "Custom Policy with Conditions"
  }
}
```

### Example 7: Key with Grants for Application

```hcl
module "app_kms_key_with_grants" {
  source = "../../modules/security/kms"

  # Customer Context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Key Configuration
  key_description = "KMS key with grants for Lambda function"
  key_purpose     = "lambda-data"

  # Key Policy
  enable_default_policy = true
  
  key_users = [
    "arn:aws:iam::123456789012:role/forge-production-lambda-execution"
  ]

  # Grants for programmatic access
  grants = [
    {
      name              = "lambda-decrypt-grant"
      grantee_principal = "arn:aws:iam::123456789012:role/forge-production-lambda-execution"
      operations        = ["Decrypt", "DescribeKey"]
      
      constraints = {
        encryption_context_equals = {
          "Department" = "Finance"
          "Project"    = "Analytics"
        }
      }
    },
    {
      name              = "ecs-encrypt-decrypt-grant"
      grantee_principal = "arn:aws:iam::123456789012:role/forge-production-ecs-task"
      operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
    }
  ]

  # Alias
  create_alias = true

  tags = {
    Purpose = "Application Data Encryption"
  }
}
```

## Key Alias Naming Convention

The module automatically generates alias names based on customer context:

### Shared Architecture
```
alias/forge-{environment}-{purpose}

Examples:
- alias/forge-production-rds
- alias/forge-production-s3
- alias/forge-staging-eks-secrets
```

### Dedicated Architecture
```
alias/{customer_name}-{purpose}

Examples:
- alias/acme-corp-rds
- alias/sanofi-s3
- alias/northrop-eks-secrets
```

### Custom Alias Names
You can override the automatic naming by providing `alias_name`:

```hcl
alias_name = "my-custom-key-alias"
```

## Key Types and Specifications

### Symmetric Keys (Default)

**Use case**: Encryption and decryption

```hcl
key_usage                = "ENCRYPT_DECRYPT"
customer_master_key_spec = "SYMMETRIC_DEFAULT"  # AES-256
enable_key_rotation      = true
```

**Supported AWS Services**:
- S3, EBS, RDS, DynamoDB, Secrets Manager, SSM Parameter Store, etc.

### Asymmetric Keys - RSA

**Use case**: Signing/verification or public key encryption

```hcl
key_usage                = "SIGN_VERIFY"  # or "ENCRYPT_DECRYPT"
customer_master_key_spec = "RSA_2048"     # or "RSA_3072", "RSA_4096"
enable_key_rotation      = false          # Not supported for asymmetric
```

**Applications**:
- Code signing
- Document signing
- TLS certificates

### Asymmetric Keys - ECC

**Use case**: Signing/verification (more efficient than RSA)

```hcl
key_usage                = "SIGN_VERIFY"
customer_master_key_spec = "ECC_NIST_P256"  # or "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1"
enable_key_rotation      = false
```

**Applications**:
- IoT device signing
- Blockchain applications (ECC_SECG_P256K1 for Bitcoin/Ethereum)

## Key Rotation

### Automatic Rotation

Enabled by default for symmetric keys:

```hcl
enable_key_rotation     = true
rotation_period_in_days = 365  # Default: annually
```

**Benefits**:
- Meets compliance requirements (PCI-DSS, HIPAA, SOC2)
- Reduces impact of key compromise
- Automatic - no application changes required

**Rotation Period Options**:
- Minimum: 90 days
- Maximum: 2560 days (7 years)
- Recommended: 365 days (annually)

**Note**: Asymmetric keys do not support automatic rotation.

### Manual Rotation

For asymmetric keys or manual control:

1. Create a new key
2. Update application configuration
3. Re-encrypt data with new key
4. Disable/delete old key after retention period

## Key Policies

### Default Policy (Recommended)

Grants IAM root account full access:

```hcl
enable_default_policy = true
```

This allows IAM policies to control access. Best practice for most use cases.

### Key Administrators

Full management permissions:

```hcl
key_administrators = [
  "arn:aws:iam::123456789012:role/InfrastructureAdmin",
  "arn:aws:iam::123456789012:user/ops-team"
]
```

**Permissions**:
- Create, Describe, Enable, Disable
- Update, Revoke, Delete
- Tag/Untag resources
- Schedule/Cancel key deletion

### Key Users

Cryptographic operations:

```hcl
key_users = [
  "arn:aws:iam::123456789012:role/ApplicationRole",
  "arn:aws:iam::123456789012:role/eks-pod-role"
]
```

**Permissions**:
- Encrypt, Decrypt, ReEncrypt
- GenerateDataKey (for envelope encryption)
- CreateGrant (for AWS resource integration)

### AWS Service Principals

Allow AWS services to use the key:

```hcl
key_service_users = [
  "s3.amazonaws.com",
  "rds.amazonaws.com",
  "lambda.amazonaws.com"
]
```

This automatically adds ViaService condition to ensure services can only use the key via their service endpoints.

## KMS Grants

Grants provide programmatic, delegated access to KMS keys:

```hcl
grants = [
  {
    name              = "lambda-decrypt"
    grantee_principal = "arn:aws:iam::123456789012:role/LambdaRole"
    operations        = ["Decrypt", "DescribeKey"]
    
    constraints = {
      encryption_context_equals = {
        "Application" = "Analytics"
      }
    }
  }
]
```

**When to use grants**:
- AWS service integration (EBS, RDS, etc.)
- Temporary access delegation
- Encryption context constraints
- Programmatic access control

**Grant Operations**:
- `Decrypt`, `Encrypt`, `GenerateDataKey`
- `ReEncryptFrom`, `ReEncryptTo`
- `CreateGrant`, `RetireGrant`
- `DescribeKey`

## Multi-Region Keys

Create a primary key in one region and replicate to others:

```hcl
multi_region = true
```

**Benefits**:
- Global applications with low latency
- Disaster recovery across regions
- Encrypt in one region, decrypt in another

**Limitations**:
- Cannot convert existing key to multi-region
- Must be created as multi-region from the start
- Replicas share key material and policies

## Cost Optimization

### KMS Pricing (US East)

| Component | Price |
|-----------|-------|
| Customer managed key | $1.00/month |
| Automatic key rotation | Included (no additional cost) |
| API requests | $0.03 per 10,000 requests |
| S3 Bucket Keys (reduces API calls) | Free |

### Tips to Reduce Costs

1. **Use S3 Bucket Keys**: Reduces KMS API calls by 99%
   ```hcl
   # In S3 module
   bucket_key_enabled = true
   ```

2. **Reuse Keys**: Use one key per service type (not per resource)
   ```
   ✓ forge-production-s3 (for all S3 buckets)
   ✗ forge-production-bucket1, forge-production-bucket2, ...
   ```

3. **Use Data Key Caching**: For high-volume encryption operations
4. **Monitor Usage**: Use CloudWatch to track API calls

## Security Best Practices

1. **Enable Automatic Rotation**: For symmetric keys (365-day cycle)
2. **Use Key Policies**: Grant least privilege access
3. **Separate Keys by Service**: RDS key ≠ S3 key ≠ EKS key
4. **Enable CloudTrail**: Audit all KMS API calls
5. **Use Encryption Context**: Add metadata for access control
6. **Set Deletion Window**: 30 days (maximum) for accidental deletion protection
7. **Tag Keys**: For cost allocation and governance
8. **Use Multi-Region Keys**: For disaster recovery
9. **Monitor Key Usage**: CloudWatch alarms for unauthorized access
10. **Avoid Embedding Keys**: Never hardcode key IDs in applications

## Encryption Context

Add metadata to encryption operations for additional security:

```python
import boto3

kms = boto3.client('kms')

# Encrypt with context
response = kms.encrypt(
    KeyId='alias/forge-production-s3',
    Plaintext=b'sensitive data',
    EncryptionContext={
        'Department': 'Finance',
        'Project': 'Q4-Report'
    }
)

# Decrypt requires same context
decrypted = kms.decrypt(
    CiphertextBlob=response['CiphertextBlob'],
    EncryptionContext={
        'Department': 'Finance',
        'Project': 'Q4-Report'
    }
)
```

## Troubleshooting

### Issue: Access denied when using key

**Error**: `User: arn:aws:iam::123456789012:role/MyRole is not authorized to perform: kms:Decrypt`

**Solutions**:
1. Check key policy grants the principal access
2. Verify IAM policy allows kms:Decrypt (if using default policy)
3. Check encryption context matches (if used)
4. Ensure key is enabled (`is_enabled = true`)

### Issue: Cannot enable rotation

**Error**: `InvalidRequestException: Automatic key rotation is not supported for asymmetric keys`

**Solution**: Rotation only works for `SYMMETRIC_DEFAULT` keys. Use manual rotation for asymmetric keys.

### Issue: Cannot delete key

**Error**: `KMSInvalidStateException: Key is pending deletion`

**Solution**: Key is in deletion window. Either:
- Wait for deletion window to expire
- Cancel deletion: `aws kms cancel-key-deletion --key-id <key-id>`

### Issue: Multi-region key replication fails

**Checklist**:
1. Primary key created with `multi_region = true`? ✓
2. Replica in different region? ✓
3. Same AWS account? ✓
4. IAM permissions for CreateKey in replica region? ✓

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| customer_id | UUID of the customer | string | n/a | yes |
| customer_name | Name of the customer | string | n/a | yes |
| architecture_type | Architecture type | string | n/a | yes |
| plan_tier | Customer plan tier | string | n/a | yes |
| environment | Environment name | string | n/a | yes |
| region | AWS region | string | n/a | yes |
| key_description | Description of the KMS key | string | "KMS key created by Terraform" | no |
| key_purpose | Purpose of the key | string | "general" | no |
| key_usage | Intended use (ENCRYPT_DECRYPT or SIGN_VERIFY) | string | "ENCRYPT_DECRYPT" | no |
| customer_master_key_spec | Key specification | string | "SYMMETRIC_DEFAULT" | no |
| multi_region | Create multi-region key | bool | false | no |
| enable_key_rotation | Enable automatic rotation | bool | true | no |
| rotation_period_in_days | Rotation period (90-2560 days) | number | 365 | no |
| deletion_window_in_days | Deletion window (7-30 days) | number | 30 | no |
| is_enabled | Whether the key is enabled | bool | true | no |
| enable_default_policy | Use default key policy | bool | true | no |
| key_administrators | IAM ARNs for key administrators | list(string) | [] | no |
| key_users | IAM ARNs for key users | list(string) | [] | no |
| key_service_users | AWS service principals | list(string) | [] | no |
| custom_key_policy | Custom key policy JSON | string | null | no |
| create_alias | Create alias for the key | bool | true | no |
| alias_name | Alias name (auto-generated if empty) | string | "" | no |
| grants | List of KMS grants | list(object) | [] | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| key_id | The globally unique identifier for the key |
| key_arn | The ARN of the key |
| key_multi_region | Whether the key is multi-region |
| key_rotation_enabled | Whether automatic rotation is enabled |
| key_rotation_period_in_days | The rotation period in days |
| alias_name | The display name of the alias |
| alias_arn | The ARN of the alias |
| alias_target_key_arn | The ARN of the target key |
| grant_ids | Map of grant names to grant IDs |
| grant_tokens | Map of grant names to grant tokens (sensitive) |
| key_purpose | The purpose of this key |
| key_usage | The intended use of the key |
| tags | All tags applied to the key |

## References

- [AWS KMS Documentation](https://docs.aws.amazon.com/kms/latest/developerguide/)
- [KMS Key Policies](https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html)
- [KMS Grants](https://docs.aws.amazon.com/kms/latest/developerguide/grants.html)
- [Multi-Region Keys](https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html)
- [Terraform AWS KMS Resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key)

## License

This module is proprietary to Moai Engineering Forge platform.
