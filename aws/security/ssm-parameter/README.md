# SSM Parameter Module

Terraform module for creating and managing AWS Systems Manager (SSM) Parameter Store parameters in the Forge platform. This module provides a consistent wrapper for parameter management with support for hierarchical organization, encryption, and customer-aware naming.

## Features

- **Hierarchical Organization**: Automatic path generation following `/ENV/resource-type/resource-id/parameter-name` pattern
- **Parameter Types**: Support for String, StringList, and SecureString parameters
- **Encryption**: KMS encryption for SecureString parameters (customer-managed or AWS-managed keys)
- **Parameter Tiers**: Standard (free, up to 4KB), Advanced (paid, up to 8KB), and Intelligent-Tiering
- **Data Validation**: Optional regex pattern validation for parameter values
- **Customer-Aware Naming**: Support for shared and dedicated architectures
- **Tagging**: Comprehensive tagging with customer context for cost allocation
- **Lifecycle Management**: Configurable overwrite behavior

## Usage

### Basic String Parameter

```hcl
module "app_config" {
  source = "../../modules/configuration/ssm-parameter"

  # Customer context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"
  environment       = "production"
  region            = "us-east-1"

  # Parameter configuration
  resource_type         = "application"
  resource_id           = "forge-production-api"
  parameter_name        = "api-endpoint"
  parameter_value       = "https://api.forge.example.com"
  parameter_type        = "String"
  parameter_description = "Forge API endpoint URL"

  tags = {
    Application = "forge-api"
    Team        = "platform"
  }
}
```

### SecureString Parameter with KMS Encryption

```hcl
module "db_password" {
  source = "../../modules/configuration/ssm-parameter"

  # Customer context
  customer_id       = "123e4567-e89b-12d3-a456-426614174000"
  customer_name     = "acme-corp"
  architecture_type = "dedicated_vpc"
  plan_tier         = "enterprise"
  environment       = "production"
  region            = "us-east-1"

  # Parameter configuration
  resource_type         = "database"
  resource_id           = "acme-corp-us-east-1-postgresql"
  parameter_name        = "password"
  parameter_value       = var.db_password
  parameter_type        = "SecureString"
  parameter_tier        = "Advanced"
  parameter_description = "PostgreSQL master password"

  # Encryption
  kms_key_id = module.kms.key_id

  tags = {
    Application = "acme-corp-db"
    Criticality = "high"
  }
}
```

### Database Connection Parameters

```hcl
# Database host
module "db_host" {
  source = "../../modules/configuration/ssm-parameter"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  resource_type         = "database"
  resource_id           = module.rds.cluster_id
  parameter_name        = "host"
  parameter_value       = module.rds.endpoint
  parameter_type        = "String"
  parameter_description = "Database cluster endpoint"
}

# Database port
module "db_port" {
  source = "../../modules/configuration/ssm-parameter"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  resource_type         = "database"
  resource_id           = module.rds.cluster_id
  parameter_name        = "port"
  parameter_value       = tostring(module.rds.port)
  parameter_type        = "String"
  parameter_description = "Database port"
}

# Database username
module "db_username" {
  source = "../../modules/configuration/ssm-parameter"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  resource_type         = "database"
  resource_id           = module.rds.cluster_id
  parameter_name        = "username"
  parameter_value       = module.rds.master_username
  parameter_type        = "SecureString"
  parameter_description = "Database master username"
  kms_key_id            = module.kms.key_id
}

# Database password
module "db_password" {
  source = "../../modules/configuration/ssm-parameter"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  resource_type         = "database"
  resource_id           = module.rds.cluster_id
  parameter_name        = "password"
  parameter_value       = module.rds.master_password
  parameter_type        = "SecureString"
  parameter_tier        = "Advanced"
  parameter_description = "Database master password"
  kms_key_id            = module.kms.key_id
}

# Connection string
module "db_connection_string" {
  source = "../../modules/configuration/ssm-parameter"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  resource_type         = "database"
  resource_id           = module.rds.cluster_id
  parameter_name        = "connection-string"
  parameter_value       = "postgresql://${module.rds.master_username}:${module.rds.master_password}@${module.rds.endpoint}:${module.rds.port}/${module.rds.database_name}"
  parameter_type        = "SecureString"
  parameter_tier        = "Advanced"
  parameter_description = "Database connection string"
  kms_key_id            = module.kms.key_id
}
```

### Cache (Redis/Memcached) Parameters

```hcl
# Primary endpoint
module "cache_primary_endpoint" {
  source = "../../modules/configuration/ssm-parameter"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  resource_type         = "cache"
  resource_id           = module.elasticache.replication_group_id
  parameter_name        = "primary-endpoint"
  parameter_value       = module.elasticache.primary_endpoint_address
  parameter_type        = "String"
  parameter_description = "Redis primary endpoint"
}

# Reader endpoint
module "cache_reader_endpoint" {
  source = "../../modules/configuration/ssm-parameter"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  resource_type         = "cache"
  resource_id           = module.elasticache.replication_group_id
  parameter_name        = "reader-endpoint"
  parameter_value       = module.elasticache.reader_endpoint_address
  parameter_type        = "String"
  parameter_description = "Redis reader endpoint"
}

# Auth token
module "cache_auth_token" {
  source = "../../modules/configuration/ssm-parameter"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  resource_type         = "cache"
  resource_id           = module.elasticache.replication_group_id
  parameter_name        = "auth-token"
  parameter_value       = module.elasticache.auth_token
  parameter_type        = "SecureString"
  parameter_description = "Redis auth token"
  kms_key_id            = module.kms.key_id
}
```

### Custom Parameter Path

```hcl
module "legacy_parameter" {
  source = "../../modules/configuration/ssm-parameter"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  # Override automatic path with custom path
  custom_path           = "/legacy/app/config/api-key"
  parameter_name        = "api-key"
  parameter_value       = var.api_key
  parameter_type        = "SecureString"
  parameter_description = "Legacy API key"
  kms_key_id            = module.kms.key_id
}
```

### Parameter with Validation Pattern

```hcl
module "email_config" {
  source = "../../modules/configuration/ssm-parameter"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  resource_type         = "application"
  resource_id           = "forge-production-api"
  parameter_name        = "support-email"
  parameter_value       = "support@forge.example.com"
  parameter_type        = "String"
  parameter_description = "Support email address"

  # Validate email format
  allowed_pattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
}
```

### EC2 Image Parameter (AMI)

```hcl
module "ec2_ami" {
  source = "../../modules/configuration/ssm-parameter"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  resource_type         = "compute"
  resource_id           = "forge-production-bastion"
  parameter_name        = "ami-id"
  parameter_value       = data.aws_ami.amazon_linux_2023.id
  parameter_type        = "String"
  parameter_description = "Amazon Linux 2023 AMI ID"

  # Use AMI data type for validation
  data_type = "aws:ec2:image"
}
```

## Parameter Path Structure

The module automatically generates hierarchical parameter paths following this pattern:

```
/ENV/resource-type/resource-id/parameter-name
```

### Examples

**Shared Architecture (Forge Platform)**:
```
/production/database/forge-production-db/host
/production/database/forge-production-db/port
/production/database/forge-production-db/username
/production/database/forge-production-db/password
/production/cache/forge-production-redis/primary-endpoint
/production/cache/forge-production-redis/auth-token
/production/application/forge-production-api/api-key
/production/config/forge-production-feature-flags/enable-new-ui
```

**Dedicated Architecture (Customer-Specific)**:
```
/production/database/acme-corp-us-east-1-postgresql/host
/production/cache/acme-corp-us-east-1-redis/primary-endpoint
/production/application/acme-corp-us-east-1-api/api-key
```

### Custom Paths

If you need to use a different path structure (e.g., for legacy compatibility), you can override the automatic path:

```hcl
custom_path = "/legacy/path/to/parameter"
```

## Parameter Types

### String
- Standard text parameters
- No encryption
- Use for non-sensitive configuration values
- Examples: endpoints, ports, feature flags

### StringList
- Comma-separated list of values
- No encryption
- Use for lists of non-sensitive values
- Example: "value1,value2,value3"

### SecureString
- Encrypted parameters using KMS
- Use for sensitive data (passwords, API keys, secrets)
- Requires KMS key ID (customer-managed) or uses AWS-managed key
- Best practice: Always use customer-managed KMS keys for production

## Parameter Tiers

### Standard (Free)
- Maximum value size: 4 KB
- Maximum parameters: 10,000 per account per region
- No additional charges
- Parameter policies: Not supported
- Use for: Most configuration parameters

### Advanced (Paid)
- Maximum value size: 8 KB
- Maximum parameters: 100,000 per account per region
- Cost: $0.05 per advanced parameter per month
- Parameter policies: Supported (expiration, notification)
- Use for: Large configuration files, certificates

### Intelligent-Tiering
- Automatically moves parameters between Standard and Advanced tiers
- Optimizes cost based on usage patterns
- Use for: Dynamic workloads with varying parameter sizes

## Data Types

### text (Default)
- Standard text validation
- Use for most parameters

### aws:ec2:image
- Validates AMI IDs
- Ensures AMI exists and is accessible
- Use for EC2 AMI parameters

### aws:ssm:integration
- Used for SSM integrations
- Advanced use cases only

## Security Best Practices

### 1. Always Encrypt Sensitive Data
```hcl
# Good: Use SecureString with KMS for passwords
parameter_type = "SecureString"
kms_key_id     = module.kms.key_id

# Bad: Never store passwords as plain String
parameter_type = "String"  # DON'T DO THIS FOR SECRETS
```

### 2. Use Customer-Managed KMS Keys
```hcl
# Good: Explicit KMS key management
kms_key_id = module.kms.key_id

# Acceptable: AWS-managed key (not recommended for production)
kms_key_id = null  # Uses aws/ssm key
```

### 3. Apply Least Privilege IAM Policies
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": "arn:aws:ssm:*:*:parameter/production/database/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:*:*:key/*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "ssm.us-east-1.amazonaws.com"
        }
      }
    }
  ]
}
```

### 4. Use Parameter Validation
```hcl
# Validate parameter format
allowed_pattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
```

### 5. Enable Overwrite Protection for Critical Parameters
```hcl
# Prevent accidental overwrite
overwrite = false
```

## Integration with Other Modules

### RDS PostgreSQL
```hcl
module "rds" {
  source = "../../modules/database/rds-postgresql"
  # ... RDS configuration ...
}

# Store RDS credentials in SSM
module "rds_params" {
  source = "../../modules/configuration/ssm-parameter"
  
  for_each = {
    host     = { value = module.rds.endpoint, type = "String" }
    port     = { value = tostring(module.rds.port), type = "String" }
    username = { value = module.rds.master_username, type = "SecureString" }
    password = { value = module.rds.master_password, type = "SecureString" }
  }

  customer_id   = var.customer_id
  customer_name = var.customer_name
  # ... other config ...

  resource_type  = "database"
  resource_id    = module.rds.cluster_id
  parameter_name = each.key
  parameter_value = each.value.value
  parameter_type  = each.value.type
  kms_key_id     = each.value.type == "SecureString" ? module.kms.key_id : null
}
```

### ElastiCache Redis
```hcl
module "elasticache" {
  source = "../../modules/cache/elasticache-redis"
  # ... ElastiCache configuration ...
}

# Store Redis connection details in SSM
module "redis_endpoint" {
  source = "../../modules/configuration/ssm-parameter"

  resource_type   = "cache"
  resource_id     = module.elasticache.replication_group_id
  parameter_name  = "primary-endpoint"
  parameter_value = module.elasticache.primary_endpoint_address
  parameter_type  = "String"
  # ... other config ...
}
```

### KMS
```hcl
module "kms" {
  source = "../../modules/security/kms"
  # ... KMS configuration ...
}

# Use KMS key for SecureString encryption
module "secure_param" {
  source = "../../modules/configuration/ssm-parameter"

  parameter_type = "SecureString"
  kms_key_id     = module.kms.key_id
  # ... other config ...
}
```

## Accessing Parameters

### AWS CLI
```bash
# Get parameter value
aws ssm get-parameter \
  --name "/production/database/forge-production-db/host" \
  --query "Parameter.Value" \
  --output text

# Get SecureString parameter (decrypted)
aws ssm get-parameter \
  --name "/production/database/forge-production-db/password" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text

# Get all parameters in a path
aws ssm get-parameters-by-path \
  --path "/production/database/forge-production-db" \
  --with-decryption
```

### Terraform Data Source
```hcl
data "aws_ssm_parameter" "db_host" {
  name = "/production/database/forge-production-db/host"
}

data "aws_ssm_parameter" "db_password" {
  name            = "/production/database/forge-production-db/password"
  with_decryption = true
}

# Use in other resources
resource "aws_instance" "app" {
  # ...
  user_data = <<-EOF
    #!/bin/bash
    DB_HOST="${data.aws_ssm_parameter.db_host.value}"
    DB_PASS="${data.aws_ssm_parameter.db_password.value}"
  EOF
}
```

### Python (boto3)
```python
import boto3

ssm = boto3.client('ssm', region_name='us-east-1')

# Get single parameter
response = ssm.get_parameter(
    Name='/production/database/forge-production-db/host'
)
print(response['Parameter']['Value'])

# Get SecureString parameter (decrypted)
response = ssm.get_parameter(
    Name='/production/database/forge-production-db/password',
    WithDecryption=True
)
print(response['Parameter']['Value'])

# Get multiple parameters
response = ssm.get_parameters(
    Names=[
        '/production/database/forge-production-db/host',
        '/production/database/forge-production-db/port',
        '/production/database/forge-production-db/username',
    ]
)
for param in response['Parameters']:
    print(f"{param['Name']}: {param['Value']}")

# Get all parameters in a path
response = ssm.get_parameters_by_path(
    Path='/production/database/forge-production-db',
    WithDecryption=True
)
```

### Application Code (Node.js)
```javascript
const { SSMClient, GetParameterCommand } = require("@aws-sdk/client-ssm");

const client = new SSMClient({ region: "us-east-1" });

async function getParameter(name, decrypt = false) {
  const command = new GetParameterCommand({
    Name: name,
    WithDecryption: decrypt
  });
  
  const response = await client.send(command);
  return response.Parameter.Value;
}

// Usage
const dbHost = await getParameter('/production/database/forge-production-db/host');
const dbPass = await getParameter('/production/database/forge-production-db/password', true);
```

## Cost Optimization

### Use Standard Tier When Possible
```hcl
# Standard tier (free) for values under 4 KB
parameter_tier = "Standard"  # Default

# Advanced tier only for large values or policy requirements
parameter_tier = "Advanced"  # $0.05/month
```

### Intelligent Tiering for Dynamic Workloads
```hcl
# Automatically optimize tier based on usage
parameter_tier = "Intelligent-Tiering"
```

### Consolidate Small Parameters
```hcl
# Instead of many small parameters:
# /app/config/param1
# /app/config/param2
# /app/config/param3

# Consider JSON parameter:
parameter_value = jsonencode({
  param1 = "value1"
  param2 = "value2"
  param3 = "value3"
})
```

## Troubleshooting

### Parameter Not Found
```bash
# Verify parameter exists
aws ssm get-parameter --name "/production/database/forge-production-db/host"

# List all parameters in path
aws ssm get-parameters-by-path --path "/production/database"
```

### Access Denied
```bash
# Check IAM permissions
aws iam get-user-policy --user-name your-user --policy-name SSMParameterAccess

# Check KMS key policy for SecureString parameters
aws kms get-key-policy --key-id <key-id> --policy-name default
```

### Parameter Value Too Large
```
Error: ValidationException: 1 validation error detected: Value '...' at 'value' failed to satisfy constraint: Member must have length less than or equal to 4096
```

**Solution**: Use Advanced tier for values 4-8 KB:
```hcl
parameter_tier = "Advanced"
```

### KMS Decryption Failed
```
Error: AccessDeniedException: User is not authorized to perform: kms:Decrypt on resource
```

**Solution**: Grant KMS decrypt permission:
```json
{
  "Effect": "Allow",
  "Action": "kms:Decrypt",
  "Resource": "arn:aws:kms:*:*:key/*",
  "Condition": {
    "StringEquals": {
      "kms:ViaService": "ssm.us-east-1.amazonaws.com"
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 6.9.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 6.9.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| customer_id | UUID of the customer | `string` | n/a | yes |
| customer_name | Name of the customer | `string` | n/a | yes |
| architecture_type | Architecture type (shared, dedicated_single_tenant, dedicated_vpc) | `string` | n/a | yes |
| plan_tier | Customer plan tier (basic, pro, enterprise, platform) | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| region | AWS region | `string` | n/a | yes |
| parameter_name | Name of the parameter | `string` | n/a | yes |
| parameter_value | Value of the parameter | `string` | n/a | yes |
| parameter_type | Type of parameter (String, StringList, SecureString) | `string` | `"String"` | no |
| parameter_description | Description of the parameter | `string` | `""` | no |
| parameter_tier | Parameter tier (Standard, Advanced, Intelligent-Tiering) | `string` | `"Standard"` | no |
| resource_type | Type of resource | `string` | `"config"` | no |
| resource_id | Identifier of the resource | `string` | `""` | no |
| custom_path | Custom parameter path (overrides automatic path) | `string` | `null` | no |
| kms_key_id | KMS key ID for SecureString encryption | `string` | `null` | no |
| data_type | Data type for parameter validation | `string` | `"text"` | no |
| allowed_pattern | Regular expression to validate parameter value | `string` | `null` | no |
| overwrite | Overwrite existing parameter value | `bool` | `true` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| parameter_name | Full name (path) of the parameter |
| parameter_arn | ARN of the parameter |
| parameter_version | Version of the parameter |
| parameter_type | Type of the parameter |
| parameter_tier | Tier of the parameter |
| parameter_data_type | Data type of the parameter |
| parameter_value | Value of the parameter (sensitive) |
| kms_key_id | KMS key ID used for SecureString encryption |
| parameter_insecure_value | Insecure value (non-SecureString only) |

## References

- [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [SSM Parameter Types](https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-types.html)
- [SSM Parameter Tiers](https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-tiers.html)
- [SSM Parameter Policies](https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-policies.html)
- [Terraform aws_ssm_parameter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter)
