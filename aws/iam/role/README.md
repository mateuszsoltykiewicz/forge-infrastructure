# IAM Role Terraform Module

This module creates an AWS IAM role with flexible trust policies, managed policy attachments, inline policies, and optional EC2 instance profile for the Forge platform.

## Features

- **Flexible Trust Policies**:
  - AWS service principals (EC2, EKS, RDS, Lambda, etc.)
  - AWS account principals (cross-account access)
  - Federated principals (OIDC for EKS IRSA, SAML for SSO)
  - Custom assume role policies
- **Policy Management**:
  - AWS managed policy attachments
  - Customer managed policy attachments
  - Inline policies for role-specific permissions
- **Instance Profile**: Automatic EC2/EKS instance profile creation
- **Permission Boundaries**: Support for permission boundaries
- **Customer-Aware**: Automatic naming and tagging based on customer context
- **Security**: Force detach policies on deletion, configurable session duration

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                       IAM Role                                │
│                                                                │
│  Trust Policy (AssumeRole)                                    │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  - AWS Services (ec2, eks, rds, lambda, ...)          │  │
│  │  - AWS Accounts (cross-account access)                │  │
│  │  - Federated (OIDC for EKS IRSA, SAML for SSO)        │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                                │
│  Attached Policies                                            │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  AWS Managed:                                          │  │
│  │  - AmazonEKSWorkerNodePolicy                           │  │
│  │  - AmazonEC2ContainerRegistryReadOnly                  │  │
│  │  - AmazonSSMManagedInstanceCore                        │  │
│  │                                                          │  │
│  │  Customer Managed:                                      │  │
│  │  - arn:aws:iam::123456789012:policy/CustomPolicy      │  │
│  │                                                          │  │
│  │  Inline Policies:                                       │  │
│  │  - s3-access                                            │  │
│  │  - kms-decrypt                                          │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                                │
│  Optional: Instance Profile (for EC2/EKS nodes)               │
└──────────────────────────────────────────────────────────────┘
```

## Usage Examples

### Example 1: EKS Node Group IAM Role

```hcl
module "eks_node_role" {
  source = "../../modules/iam/iam-role"

  # Customer Context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Role Configuration
  role_purpose    = "eks-node"
  role_description = "IAM role for EKS worker nodes"
  max_session_duration = 3600

  # Trust Policy - Allow EC2 service to assume this role
  trusted_services = ["ec2.amazonaws.com"]

  # AWS Managed Policies for EKS Nodes
  aws_managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  # Create Instance Profile for EC2 instances
  create_instance_profile = true

  tags = {
    Purpose = "EKS Node Group"
  }
}
```

### Example 2: EKS Pod IAM Role (IRSA - IAM Roles for Service Accounts)

```hcl
# First, get the OIDC provider URL from EKS cluster
data "aws_eks_cluster" "main" {
  name = "forge-production-eks"
}

locals {
  oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/${replace(data.aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}"
  oidc_provider_url = replace(data.aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}

module "eks_pod_s3_access_role" {
  source = "../../modules/iam/iam-role"

  # Customer Context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Role Configuration
  role_purpose    = "eks-pod-s3-access"
  role_description = "IAM role for EKS pods to access S3 via IRSA"

  # Trust Policy - OIDC provider with service account condition
  trusted_federated_arns = [local.oidc_provider_arn]
  
  oidc_condition = {
    test     = "StringEquals"
    variable = "${local.oidc_provider_url}:sub"
    values   = ["system:serviceaccount:default:s3-access-sa"]
  }

  # Inline policy for S3 access
  inline_policies = {
    "s3-access" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket"
          ]
          Resource = [
            "arn:aws:s3:::forge-production-data",
            "arn:aws:s3:::forge-production-data/*"
          ]
        }
      ]
    })
  }

  tags = {
    Purpose         = "EKS Pod S3 Access"
    ServiceAccount  = "s3-access-sa"
    Namespace       = "default"
  }
}
```

### Example 3: RDS Enhanced Monitoring Role

```hcl
module "rds_monitoring_role" {
  source = "../../modules/iam/iam-role"

  # Customer Context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Role Configuration
  role_purpose    = "rds-monitoring"
  role_description = "IAM role for RDS Enhanced Monitoring"

  # Trust Policy - Allow RDS monitoring service
  trusted_services = ["monitoring.rds.amazonaws.com"]

  # AWS Managed Policy for RDS Enhanced Monitoring
  aws_managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  ]

  tags = {
    Purpose = "RDS Enhanced Monitoring"
  }
}
```

### Example 4: S3 Cross-Region Replication Role

```hcl
module "s3_replication_role" {
  source = "../../modules/iam/iam-role"

  # Customer Context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Role Configuration
  role_purpose    = "s3-replication"
  role_description = "IAM role for S3 cross-region replication"

  # Trust Policy - Allow S3 service
  trusted_services = ["s3.amazonaws.com"]

  # Inline policy for S3 replication
  inline_policies = {
    "s3-replication-policy" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetReplicationConfiguration",
            "s3:ListBucket"
          ]
          Resource = "arn:aws:s3:::forge-production-terraform-state"
        },
        {
          Effect = "Allow"
          Action = [
            "s3:GetObjectVersionForReplication",
            "s3:GetObjectVersionAcl",
            "s3:GetObjectVersionTagging"
          ]
          Resource = "arn:aws:s3:::forge-production-terraform-state/*"
        },
        {
          Effect = "Allow"
          Action = [
            "s3:ReplicateObject",
            "s3:ReplicateDelete",
            "s3:ReplicateTags"
          ]
          Resource = "arn:aws:s3:::forge-production-terraform-state-dr/*"
        },
        {
          Effect = "Allow"
          Action = [
            "kms:Decrypt"
          ]
          Resource = "arn:aws:kms:us-east-1:123456789012:key/source-key-id"
          Condition = {
            StringLike = {
              "kms:ViaService" = "s3.us-east-1.amazonaws.com"
            }
          }
        },
        {
          Effect = "Allow"
          Action = [
            "kms:Encrypt"
          ]
          Resource = "arn:aws:kms:us-west-2:123456789012:key/destination-key-id"
          Condition = {
            StringLike = {
              "kms:ViaService" = "s3.us-west-2.amazonaws.com"
            }
          }
        }
      ]
    })
  }

  tags = {
    Purpose = "S3 Replication"
  }
}
```

### Example 5: Lambda Execution Role

```hcl
module "lambda_execution_role" {
  source = "../../modules/iam/iam-role"

  # Customer Context
  customer_id       = "cust-123e4567-e89b-12d3-a456-426614174000"
  customer_name     = "acme-corp"
  architecture_type = "dedicated"
  plan_tier         = "enterprise"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Role Configuration
  role_purpose    = "lambda-execution"
  role_description = "IAM role for Lambda function execution"

  # Trust Policy - Allow Lambda service
  trusted_services = ["lambda.amazonaws.com"]

  # AWS Managed Policies for Lambda
  aws_managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]

  # Inline policy for specific resources
  inline_policies = {
    "dynamodb-access" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:Query"
          ]
          Resource = "arn:aws:dynamodb:us-east-1:123456789012:table/acme-corp-data"
        }
      ]
    })
  }

  tags = {
    Purpose = "Lambda Execution"
  }
}
```

### Example 6: Cross-Account Access Role

```hcl
module "cross_account_role" {
  source = "../../modules/iam/iam-role"

  # Customer Context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Role Configuration
  role_purpose    = "cross-account-access"
  role_description = "IAM role for cross-account access from dev account"
  max_session_duration = 43200  # 12 hours

  # Trust Policy - Allow specific AWS account
  trusted_aws_accounts = ["987654321098"]  # Dev account ID

  # AWS Managed Policies
  aws_managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]

  # Inline policy for write access to specific resources
  inline_policies = {
    "write-access" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:DeleteObject"
          ]
          Resource = "arn:aws:s3:::forge-production-shared/*"
        }
      ]
    })
  }

  tags = {
    Purpose       = "Cross-Account Access"
    TrustedAccount = "987654321098"
  }
}
```

### Example 7: Custom Assume Role Policy

```hcl
module "custom_trust_role" {
  source = "../../modules/iam/iam-role"

  # Customer Context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # Role Configuration
  role_purpose    = "custom-trust"
  role_description = "IAM role with custom trust policy"

  # Custom Assume Role Policy (full control)
  custom_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = "10.0.0.0/8"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "unique-external-id-12345"
          }
        }
      }
    ]
  })

  aws_managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]

  tags = {
    Purpose = "Custom Trust Policy"
  }
}
```

## Role Naming Convention

The module automatically generates role names based on customer context:

### Shared Architecture
```
forge-{environment}-{purpose}

Examples:
- forge-production-eks-node
- forge-production-rds-monitoring
- forge-staging-lambda-execution
```

### Dedicated Architecture
```
{customer_name}-{purpose}

Examples:
- acme-corp-eks-node
- sanofi-rds-monitoring
- northrop-lambda-execution
```

### Custom Names
You can override the automatic naming by providing `role_name`:

```hcl
role_name = "my-custom-role-name"
```

## Trust Policy Configuration

### AWS Service Principals

Common AWS services that can assume roles:

| Service | Principal |
|---------|-----------|
| EC2 | `ec2.amazonaws.com` |
| EKS | `eks.amazonaws.com` |
| Lambda | `lambda.amazonaws.com` |
| RDS | `rds.amazonaws.com` |
| RDS Monitoring | `monitoring.rds.amazonaws.com` |
| S3 | `s3.amazonaws.com` |
| CodeBuild | `codebuild.amazonaws.com` |
| CodePipeline | `codepipeline.amazonaws.com` |
| ECS Tasks | `ecs-tasks.amazonaws.com` |

```hcl
trusted_services = [
  "ec2.amazonaws.com",
  "eks.amazonaws.com"
]
```

### Cross-Account Access

Allow other AWS accounts to assume this role:

```hcl
trusted_aws_accounts = [
  "123456789012",  # Dev account
  "987654321098"   # Staging account
]
```

Resulting trust policy:
```json
{
  "Effect": "Allow",
  "Principal": {
    "AWS": [
      "arn:aws:iam::123456789012:root",
      "arn:aws:iam::987654321098:root"
    ]
  },
  "Action": "sts:AssumeRole"
}
```

### OIDC for EKS IRSA

Allow Kubernetes service accounts to assume roles:

```hcl
trusted_federated_arns = ["arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"]

oidc_condition = {
  test     = "StringEquals"
  variable = "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E:sub"
  values   = [
    "system:serviceaccount:default:my-service-account"
  ]
}
```

**Multiple Service Accounts**:
```hcl
oidc_condition = {
  test     = "StringEquals"
  variable = "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E:sub"
  values   = [
    "system:serviceaccount:default:app1-sa",
    "system:serviceaccount:default:app2-sa",
    "system:serviceaccount:monitoring:prometheus-sa"
  ]
}
```

## Policy Management

### AWS Managed Policies

Use AWS-maintained policies for common use cases:

```hcl
aws_managed_policy_arns = [
  "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
  "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
]
```

**Common AWS Managed Policies**:
- `ReadOnlyAccess` - Read-only access to all AWS services
- `PowerUserAccess` - Full access except IAM/Organizations
- `AmazonEKSWorkerNodePolicy` - EKS worker node permissions
- `AmazonEKS_CNI_Policy` - EKS VPC CNI plugin
- `AmazonSSMManagedInstanceCore` - SSM Session Manager
- `service-role/AmazonRDSEnhancedMonitoringRole` - RDS monitoring

### Customer Managed Policies

Attach your own IAM policies:

```hcl
customer_managed_policy_arns = [
  "arn:aws:iam::123456789012:policy/MyCustomPolicy",
  "arn:aws:iam::123456789012:policy/TeamPolicy"
]
```

### Inline Policies

Define role-specific policies inline:

```hcl
inline_policies = {
  "s3-access" = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject"]
        Resource = "arn:aws:s3:::my-bucket/*"
      }
    ]
  })
  
  "kms-decrypt" = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["kms:Decrypt"]
        Resource = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      }
    ]
  })
}
```

## Permission Boundaries

Set a permission boundary to limit the maximum permissions:

```hcl
permissions_boundary_arn = "arn:aws:iam::123456789012:policy/DeveloperBoundary"
```

Permission boundaries ensure that even if the role has broad permissions, it cannot exceed the boundary policy.

## Instance Profiles

For EC2 instances and EKS node groups:

```hcl
create_instance_profile = true
```

This automatically creates an instance profile with the same name as the role, which can be attached to EC2 instances.

## Session Duration

Control how long assumed role sessions last:

```hcl
max_session_duration = 3600   # 1 hour (default)
max_session_duration = 14400  # 4 hours
max_session_duration = 43200  # 12 hours (maximum)
```

## Security Best Practices

1. **Principle of Least Privilege**: Grant only the permissions necessary
2. **Use Permission Boundaries**: Limit maximum permissions for delegated roles
3. **Require External ID**: For cross-account access to prevent confused deputy
4. **Use OIDC for EKS**: Prefer IRSA over node-level permissions
5. **Rotate Long-Term Credentials**: Use temporary credentials from AssumeRole
6. **Monitor IAM Usage**: Enable CloudTrail and review access patterns
7. **Use Conditions**: Add IP address, MFA, or time-based conditions
8. **Separate Roles**: Create specific roles for different purposes (don't reuse)

## Common Use Cases

### EKS Node Group
- Trust: `ec2.amazonaws.com`
- Policies: `AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKS_CNI_Policy`
- Instance Profile: Yes

### EKS Pod (IRSA)
- Trust: OIDC provider with service account condition
- Policies: Resource-specific inline policies
- Instance Profile: No

### RDS Enhanced Monitoring
- Trust: `monitoring.rds.amazonaws.com`
- Policies: `AmazonRDSEnhancedMonitoringRole`
- Instance Profile: No

### S3 Replication
- Trust: `s3.amazonaws.com`
- Policies: Custom inline policy for source/destination buckets
- Instance Profile: No

### Lambda Execution
- Trust: `lambda.amazonaws.com`
- Policies: `AWSLambdaBasicExecutionRole`, custom inline policies
- Instance Profile: No

## Troubleshooting

### Issue: Cannot assume role

**Error**: `User: arn:aws:iam::123456789012:user/john is not authorized to perform: sts:AssumeRole`

**Solutions**:
1. Check trust policy allows the principal
2. Verify IAM user/role has `sts:AssumeRole` permission
3. Check for deny statements in policies
4. Verify external ID (if required)

### Issue: Access denied after assuming role

**Error**: `User: arn:aws:sts::123456789012:assumed-role/my-role/session is not authorized to perform: s3:GetObject`

**Solutions**:
1. Check attached policies grant the action
2. Verify permission boundary doesn't deny it
3. Check resource-based policies (S3 bucket policy)
4. Review SCPs if using AWS Organizations

### Issue: OIDC trust policy not working

**Checklist**:
1. OIDC provider registered in IAM? ✓
2. Service account annotated with role ARN? ✓
3. OIDC condition matches service account namespace:name? ✓
4. Pod using the service account? ✓

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| customer_id | UUID of the customer | string | n/a | yes |
| customer_name | Name of the customer | string | n/a | yes |
| architecture_type | Architecture type | string | n/a | yes |
| plan_tier | Customer plan tier | string | n/a | yes |
| environment | Environment name | string | n/a | yes |
| region | AWS region | string | n/a | yes |
| role_name | IAM role name (auto-generated if empty) | string | "" | no |
| role_description | Description of the IAM role | string | "IAM role created by Terraform" | no |
| role_purpose | Purpose of the role | string | "general" | no |
| max_session_duration | Maximum session duration (seconds) | number | 3600 | no |
| force_detach_policies | Force detach policies on deletion | bool | true | no |
| trusted_services | AWS services that can assume this role | list(string) | [] | no |
| trusted_aws_accounts | AWS account IDs that can assume this role | list(string) | [] | no |
| trusted_federated_arns | Federated ARNs (OIDC/SAML) | list(string) | [] | no |
| oidc_condition | OIDC condition for EKS IRSA | object | null | no |
| custom_assume_role_policy | Custom assume role policy JSON | string | null | no |
| aws_managed_policy_arns | AWS managed policy ARNs | list(string) | [] | no |
| customer_managed_policy_arns | Customer managed policy ARNs | list(string) | [] | no |
| inline_policies | Map of inline policy names to documents | map(string) | {} | no |
| create_instance_profile | Create EC2 instance profile | bool | false | no |
| permissions_boundary_arn | Permissions boundary ARN | string | null | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| role_name | The name of the IAM role |
| role_arn | The ARN of the IAM role |
| role_id | The unique ID of the IAM role |
| role_path | The path of the IAM role |
| instance_profile_name | The name of the instance profile (if created) |
| instance_profile_arn | The ARN of the instance profile (if created) |
| instance_profile_id | The unique ID of the instance profile (if created) |
| aws_managed_policy_arns | List of attached AWS managed policy ARNs |
| customer_managed_policy_arns | List of attached customer managed policy ARNs |
| inline_policy_names | List of inline policy names |
| role_purpose | The purpose of this role |
| tags | All tags applied to the role |

## References

- [AWS IAM Roles Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)
- [IAM Roles for Service Accounts (IRSA)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [Permission Boundaries](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html)
- [Terraform AWS IAM Resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)

## License

This module is proprietary to Moai Engineering Forge platform.
