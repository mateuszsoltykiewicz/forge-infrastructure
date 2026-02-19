# VPC Module (Forge - Customer-Centric)

Creates an AWS Virtual Private Cloud (VPC) with DNS support and customer-aware tagging.

## Features

- **Customer-Centric Design**: Supports both shared and dedicated customer architectures
- **DNS Enabled**: Automatic DNS support and hostnames for service discovery
- **Flexible Tagging**: Customer-aware tags for accurate cost allocation
- **Architecture Support**: Handles shared, dedicated_local, and dedicated_regional deployments
- **Best Practices**: Follows AWS and Terraform recommended patterns
- **No Provider Lock-in**: Provider configured at root level for maximum flexibility

---

## Provider Configuration

**Important**: This module does **NOT** include provider configuration.

Providers should be configured in your **root module** (not in child modules). This follows Terraform best practices and allows:
- ✅ Different authentication methods per environment
- ✅ Customer-specific AWS account access
- ✅ Multi-region deployments with provider aliases
- ✅ CloudOrchestrator dynamic provider generation

**Example provider configuration** (in root module):

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.9"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      ManagedBy   = "Forge"
      Environment = "production"
    }
  }
}

module "vpc" {
  source = "./modules/network/vpc"
  # ... module variables
}
```

See [Provider Configuration Guide](../../PROVIDER_CONFIGURATION.md) for detailed examples including IAM role assumption and multi-region setups.

---

## Architecture Support

### Shared Architecture (Multi-Tenant)
- **Single VPC** serves multiple customers via Kubernetes namespaces
- **No customer_id** or customer_name required
- **Naming**: `forge-{workspace}-{environment}`
- **Use Case**: Trial and Basic plan tiers

### Dedicated Local Architecture (Single Region)
- **One VPC per customer** in a single region
- **Requires** customer_id and customer_name
- **Naming**: `{customer_name}-{region}`
- **Use Case**: Pro plan tier

### Dedicated Regional Architecture (Multi-Region)
- **Multiple regional VPCs** per customer
- **Requires** customer_id and customer_name
- **Naming**: `{customer_name}-{region}`
- **Use Case**: Enterprise plan tier

---

## Usage Examples

### Example 1: Shared VPC (Forge Control Plane)

```hcl
module "forge_vpc" {
  source = "./modules/network/vpc"
  
  # VPC Configuration
  vpc_name   = "forge-production-vpc"
  cidr_block = "10.0.0.0/16"
  
  # Forge Infrastructure Context
  workspace      = "production"
  environment    = "prod"
  aws_region     = "us-east-1"
  
  # Shared architecture (no customer context)
  architecture_type = "shared"
  
  # Tagging
  common_tags = {
    Component = "Forge Control Plane"
    Team      = "Platform Engineering"
  }
}
```

**Output**:
- VPC Name: `forge-production-vpc`
- Tags Include: `ManagedBy = "Forge"`, `ArchitectureType = "shared"`
- No customer-specific tags

---

### Example 2: Dedicated Customer VPC (Pro Tier)

```hcl
module "customer_vpc" {
  source = "./modules/network/vpc"
  
  # VPC Configuration
  vpc_name   = "customer-us-east-1-vpc"
  cidr_block = "10.100.0.0/16"
  
  # Forge Infrastructure Context
  workspace      = "production"
  environment    = "prod"
  aws_region     = "us-east-1"
  
  # Customer Context (from Forge database)
  customer_id       = "550e8400-e29b-41d4-a716-446655440000"
  customer_name     = "customer"
  architecture_type = "dedicated_local"
  plan_tier         = "pro"
  
  # Tagging
  common_tags = {
    Criticality = "high"
    Compliance  = "hipaa"
  }
}
```

**Output**:
- VPC Name: `customer-us-east-1-vpc`
- Tags Include:
  - `ManagedBy = "Forge"`
  - `CustomerId = "550e8400-e29b-41d4-a716-446655440000"`
  - `CustomerName = "customer"`
  - `ArchitectureType = "dedicated_local"`
  - `PlanTier = "pro"`

---

### Example 3: Multi-Region Customer VPC (Enterprise Tier)

```hcl
# US East Region
module "customer_vpc_us_east" {
  source = "./modules/network/vpc"
  
  vpc_name   = "acme-us-east-1-vpc"
  cidr_block = "10.200.0.0/16"
  
  workspace         = "production"
  environment       = "prod"
  aws_region        = "us-east-1"
  
  customer_id       = "660e8400-e29b-41d4-a716-446655440001"
  customer_name     = "acme"
  architecture_type = "dedicated_regional"
  plan_tier         = "enterprise"
}

# EU West Region
module "customer_vpc_eu_west" {
  source = "./modules/network/vpc"
  
  vpc_name   = "acme-eu-west-1-vpc"
  cidr_block = "10.201.0.0/16"
  
  workspace         = "production"
  environment       = "prod"
  aws_region        = "eu-west-1"
  
  customer_id       = "660e8400-e29b-41d4-a716-446655440001"
  customer_name     = "acme"
  architecture_type = "dedicated_regional"
  plan_tier         = "enterprise"
}
```

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `vpc_name` | Name of the VPC | `string` | n/a | yes |
| `cidr_block` | Primary CIDR block for VPC | `string` | n/a | yes |
| `workspace` | Terraform workspace name | `string` | n/a | yes |
| `environment` | Environment identifier | `string` | n/a | yes |
| `aws_region` | AWS region for deployment | `string` | n/a | yes |
| `customer_id` | Customer UUID (null for shared) | `string` | `null` | no |
| `customer_name` | Customer name (null for shared) | `string` | `null` | no |
| `architecture_type` | Architecture model | `string` | `"shared"` | no |
| `plan_tier` | Customer plan tier | `string` | `null` | no |
| `common_tags` | Additional resource tags | `map(string)` | `{}` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | The ID of the created VPC |
| `vpc_arn` | The ARN of the created VPC |
| `vpc_name` | The name of the VPC |
| `cidr_block` | The CIDR block of the VPC |
| `workspace` | The workspace associated with this VPC |
| `environment` | The environment (prod, staging, dev) |
| `aws_region` | The AWS region of deployment |
| `architecture_type` | The architecture deployment model |
| `customer_id` | The customer UUID (null for shared) |
| `customer_name` | The customer name (null for shared) |
| `enable_dns_support` | DNS resolution enabled status |
| `enable_dns_hostnames` | DNS hostnames enabled status |

---

## CIDR Block Recommendations

### Shared VPCs (Forge Control Plane)
- **Production**: `10.0.0.0/16` (65,536 IPs)
- **Staging**: `10.1.0.0/16`
- **Development**: `10.2.0.0/16`

### Dedicated Customer VPCs
- **Pro Tier** (dedicated_local): `/16` networks (65,536 IPs)
  - Example: `10.100.0.0/16`, `10.101.0.0/16`, etc.
- **Enterprise Tier** (dedicated_regional): `/16` networks per region
  - Example: Customer A: `10.200.0.0/16` (us-east-1), `10.201.0.0/16` (eu-west-1)

### CIDR Allocation Strategy
- Reserve `10.0.0.0/16` - `10.9.0.0/16` for Forge infrastructure
- Reserve `10.10.0.0/16` - `10.99.0.0/16` for future use
- Allocate `10.100.0.0/16` - `10.255.0.0/16` for customer VPCs

---

## Best Practices

### Naming Conventions
- **Shared**: `forge-{workspace}-{environment}-vpc`
- **Dedicated**: `{customer_name}-{region}-vpc`

### Tagging Strategy
- Always include `ManagedBy = "Forge"` for all resources
- Add `CustomerId` and `CustomerName` for dedicated VPCs
- Use `ArchitectureType` to identify isolation level
- Include `PlanTier` for cost allocation reports

### Security Considerations
- Enable DNS support and hostnames for service discovery
- Ensure CIDR blocks don't overlap with customer on-premise networks
- Document CIDR allocations in Forge database
- Use VPC Flow Logs for security monitoring (configured separately)

### Cost Optimization
- Use shared VPCs for Trial and Basic tiers
- Only provision dedicated VPCs for Pro and Enterprise tiers
- Monitor VPC costs with customer-specific tags
- Consider VPC sharing for enterprise multi-account setups

---

## Dependencies

This module has no dependencies and can be used standalone.

**Downstream Modules** (use this VPC):
- `network/subnet` - Creates subnets within VPC
- `network/internet_gateway` - Attaches IGW to VPC
- `network/security_groups` - Creates security groups in VPC
- `compute/eks` - Deploys EKS cluster in VPC
- `database/rds_postgresql` - Deploys RDS in VPC

---

## Integration with Forge Database

Customer VPCs are tracked in the Forge PostgreSQL database:

```sql
-- Example: Query customer VPCs
SELECT 
  c.name AS customer_name,
  cc.cluster_name,
  cc.vpc_id,
  cc.cluster_type,
  cp.name AS plan_tier
FROM customers c
JOIN customer_clusters cc ON c.id = cc.customer_id
JOIN customer_plans cp ON c.plan_id = cp.id
WHERE cp.architecture_type IN ('dedicated_local', 'dedicated_regional');
```

---

## Backend Configuration

This module includes a `backend.tf` file for S3 remote state storage.

**Important**: The backend is **commented out by default** because:
1. The **bootstrap module must be run first** to create S3 bucket and DynamoDB table
2. After bootstrap, uncomment the backend configuration
3. Run `terraform init -migrate-state` to move state to S3

See [Backend Configuration Guide](../../../backend/README.md) for complete setup instructions.

---

## Testing

### Validate Configuration
```bash
cd infrastructure/terraform/modules/network/vpc
terraform init
terraform validate
```

### Format Code
```bash
terraform fmt -recursive
```

### Run Tests (Future)
```bash
# TODO: Add terratest integration tests
# - Test shared VPC creation
# - Test dedicated VPC with customer context
# - Validate tagging strategy
# - Verify DNS settings
```

---

## Changelog

### Version 1.0.0 (Initial - Forge)
- Migrated from cloud-platform-features VPC module
- Added customer context support (customer_id, customer_name)
- Added architecture_type variable (shared, dedicated_local, dedicated_regional)
- Enhanced tagging strategy for customer cost allocation
- Updated naming conventions for Forge platform
- Added plan_tier support for cost reporting
- Improved documentation with customer-centric examples

---

## Authors

**MOAI Engineering - Platform Team**

**Source**: Adapted from `cloud-platform-features/iac/aws/terraform/modules/network/vpc/`

---

## License

Internal use only - MOAI Engineering
