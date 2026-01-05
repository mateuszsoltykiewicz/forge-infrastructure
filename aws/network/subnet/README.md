# Subnet Module (Forge - Customer-Centric)

Creates AWS subnets within a VPC with public/private tier classification, route tables, and customer-aware tagging.

## Features

- **Multi-AZ Support**: Deploy subnets across multiple availability zones for high availability
- **Public/Private Tiers**: Automatic route table management for internet and private access
- **Purpose-Based Organization**: Tag subnets by purpose (eks, database, application, etc.)
- **Customer-Centric Tagging**: Inherits customer context for cost allocation
- **Flexible Configuration**: List-based subnet definition with validation
- **No Provider Lock-in**: Provider configured at root level

---

## Dependencies

**Requires**:
- VPC module output (`vpc_id`)

**Used By**:
- Internet Gateway module (public subnets)
- NAT Gateway module (public subnets for NAT, private subnets for routing)
- EKS module (private subnets for nodes)
- RDS module (private subnets for databases)
- ALB/NLB modules (public subnets for load balancers)

---

## Usage Examples

### Example 1: Shared Forge Infrastructure (3 AZs)

```hcl
module "forge_vpc" {
  source = "./modules/network/vpc"
  
  vpc_name          = "forge-production-vpc"
  cidr_block        = "10.0.0.0/16"
  workspace         = "production"
  environment       = "prod"
  aws_region        = "us-east-1"
  architecture_type = "shared"
}

module "forge_subnets" {
  source = "./modules/network/subnet"
  
  vpc_id   = module.forge_vpc.vpc_id
  vpc_name = module.forge_vpc.vpc_name
  
  subnets = [
    # Public subnets (for ALB, NAT Gateway)
    {
      name              = "public-us-east-1a"
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
      tier              = "public"
      purpose           = "loadbalancer"
    },
    {
      name              = "public-us-east-1b"
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-1b"
      tier              = "public"
      purpose           = "loadbalancer"
    },
    {
      name              = "public-us-east-1c"
      cidr_block        = "10.0.3.0/24"
      availability_zone = "us-east-1c"
      tier              = "public"
      purpose           = "loadbalancer"
    },
    
    # Private subnets (for EKS nodes)
    {
      name              = "eks-us-east-1a"
      cidr_block        = "10.0.11.0/24"
      availability_zone = "us-east-1a"
      tier              = "private"
      purpose           = "eks"
    },
    {
      name              = "eks-us-east-1b"
      cidr_block        = "10.0.12.0/24"
      availability_zone = "us-east-1b"
      tier              = "private"
      purpose           = "eks"
    },
    {
      name              = "eks-us-east-1c"
      cidr_block        = "10.0.13.0/24"
      availability_zone = "us-east-1c"
      tier              = "private"
      purpose           = "eks"
    },
    
    # Private subnets (for RDS)
    {
      name              = "database-us-east-1a"
      cidr_block        = "10.0.21.0/24"
      availability_zone = "us-east-1a"
      tier              = "private"
      purpose           = "database"
    },
    {
      name              = "database-us-east-1b"
      cidr_block        = "10.0.22.0/24"
      availability_zone = "us-east-1b"
      tier              = "private"
      purpose           = "database"
    },
    {
      name              = "database-us-east-1c"
      cidr_block        = "10.0.23.0/24"
      availability_zone = "us-east-1c"
      tier              = "private"
      purpose           = "database"
    },
  ]
  
  workspace         = "production"
  environment       = "prod"
  aws_region        = "us-east-1"
  architecture_type = "shared"
}
```

**Output**:
- ✅ 9 subnets created (3 public, 6 private)
- ✅ 2 route tables created (public, private)
- ✅ All subnets tagged with `ManagedBy = "Forge"`

---

### Example 2: Customer Dedicated VPC (Pro Tier)

```hcl
module "customer_vpc" {
  source = "./modules/network/vpc"
  
  vpc_name          = "sanofi-us-east-1-vpc"
  cidr_block        = "10.100.0.0/16"
  workspace         = "production"
  environment       = "prod"
  aws_region        = "us-east-1"
  customer_id       = "550e8400-e29b-41d4-a716-446655440000"
  customer_name     = "sanofi"
  architecture_type = "dedicated_local"
  plan_tier         = "pro"
}

module "customer_subnets" {
  source = "./modules/network/subnet"
  
  vpc_id   = module.customer_vpc.vpc_id
  vpc_name = module.customer_vpc.vpc_name
  
  subnets = [
    # Public subnets
    {
      name              = "sanofi-public-us-east-1a"
      cidr_block        = "10.100.1.0/24"
      availability_zone = "us-east-1a"
      tier              = "public"
      purpose           = "loadbalancer"
    },
    {
      name              = "sanofi-public-us-east-1b"
      cidr_block        = "10.100.2.0/24"
      availability_zone = "us-east-1b"
      tier              = "public"
      purpose           = "loadbalancer"
    },
    
    # Private subnets for EKS
    {
      name              = "sanofi-eks-us-east-1a"
      cidr_block        = "10.100.11.0/24"
      availability_zone = "us-east-1a"
      tier              = "private"
      purpose           = "eks"
    },
    {
      name              = "sanofi-eks-us-east-1b"
      cidr_block        = "10.100.12.0/24"
      availability_zone = "us-east-1b"
      tier              = "private"
      purpose           = "eks"
    },
    
    # Private subnets for Database
    {
      name              = "sanofi-database-us-east-1a"
      cidr_block        = "10.100.21.0/24"
      availability_zone = "us-east-1a"
      tier              = "private"
      purpose           = "database"
    },
    {
      name              = "sanofi-database-us-east-1b"
      cidr_block        = "10.100.22.0/24"
      availability_zone = "us-east-1b"
      tier              = "private"
      purpose           = "database"
    },
  ]
  
  workspace         = "production"
  environment       = "prod"
  aws_region        = "us-east-1"
  customer_id       = "550e8400-e29b-41d4-a716-446655440000"
  customer_name     = "sanofi"
  architecture_type = "dedicated_local"
  plan_tier         = "pro"
}
```

**Output Tags** (includes customer context):
```
ManagedBy        = "Forge"
CustomerId       = "550e8400-e29b-41d4-a716-446655440000"
CustomerName     = "sanofi"
ArchitectureType = "dedicated_local"
PlanTier         = "pro"
Tier             = "Public" or "Private"
Purpose          = "eks", "database", "loadbalancer"
```

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `vpc_id` | VPC ID where subnets will be created | `string` | n/a | yes |
| `vpc_name` | VPC name (for route table naming) | `string` | n/a | yes |
| `subnets` | List of subnet configurations | `list(object)` | n/a | yes |
| `workspace` | Terraform workspace name | `string` | n/a | yes |
| `environment` | Environment identifier | `string` | n/a | yes |
| `aws_region` | AWS region | `string` | n/a | yes |
| `customer_id` | Customer UUID (null for shared) | `string` | `null` | no |
| `customer_name` | Customer name (null for shared) | `string` | `null` | no |
| `architecture_type` | Architecture model | `string` | `"shared"` | no |
| `plan_tier` | Customer plan tier | `string` | `null` | no |
| `common_tags` | Additional resource tags | `map(string)` | `{}` | no |

### Subnet Object Schema

```hcl
{
  name              = string # Unique subnet name
  cidr_block        = string # CIDR notation (e.g., "10.0.1.0/24")
  availability_zone = string # Full AZ name (e.g., "us-east-1a")
  tier              = string # "public" or "private"
  purpose           = string # Purpose tag (e.g., "eks", "database", "loadbalancer")
}
```

---

## Outputs

| Name | Description |
|------|-------------|
| `subnet_ids` | Map of subnet names to IDs |
| `subnet_ids_list` | List of all subnet IDs |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `subnet_details` | Detailed subnet information |
| `subnets_by_tier` | Subnets grouped by tier |
| `subnets_by_purpose` | Subnets grouped by purpose |
| `subnets_by_az` | Subnets grouped by AZ |
| `route_table_ids` | Map of route table types to IDs |
| `public_route_table_id` | Public route table ID |
| `private_route_table_id` | Private route table ID |
| `subnet_configuration_summary` | Configuration summary |

---

## CIDR Block Planning

### Shared Forge VPC (10.0.0.0/16)

```
10.0.0.0/16 (65,536 IPs total)
├─ 10.0.1.0/24 - 10.0.3.0/24   Public subnets (3 AZs)           768 IPs
├─ 10.0.11.0/24 - 10.0.13.0/24 EKS private subnets (3 AZs)      768 IPs
├─ 10.0.21.0/24 - 10.0.23.0/24 Database private subnets (3 AZs) 768 IPs
└─ 10.0.31.0/24 - 10.0.33.0/24 Cache private subnets (3 AZs)    768 IPs
```

### Customer VPC (10.100.0.0/16)

```
10.100.0.0/16 (65,536 IPs total)
├─ 10.100.1.0/24 - 10.100.2.0/24  Public subnets (2 AZs)      512 IPs
├─ 10.100.11.0/24 - 10.100.12.0/24 EKS subnets (2 AZs)        512 IPs
└─ 10.100.21.0/24 - 10.100.22.0/24 Database subnets (2 AZs)   512 IPs
```

---

## Best Practices

### High Availability
- ✅ Use at least **2 AZs** (3 recommended for production)
- ✅ Distribute subnets evenly across AZs
- ✅ Same purpose subnets in each AZ (e.g., eks in 1a, 1b, 1c)

### Naming Convention
```
{customer_name}-{purpose}-{az}-{tier}
Examples:
- forge-eks-us-east-1a-private
- sanofi-database-us-east-1a-private
- acme-loadbalancer-us-east-1b-public
```

### Subnet Sizing
- **Public subnets**: /24 (256 IPs) - For ALB, NAT Gateway
- **EKS subnets**: /24 or /23 (256-512 IPs) - Depends on pod count
- **Database subnets**: /24 (256 IPs) - For RDS, ElastiCache
- **Reserve space**: Don't use entire VPC CIDR

### Tier Usage
- **Public** (`tier = "public"`):
  - Application Load Balancers
  - Network Load Balancers
  - NAT Gateways
  - Bastion hosts
  
- **Private** (`tier = "private"`):
  - EKS worker nodes
  - RDS databases
  - ElastiCache clusters
  - Application servers

### Purpose Tags
Common purposes:
- `eks` - EKS worker nodes
- `database` - RDS, Aurora
- `cache` - ElastiCache
- `loadbalancer` - ALB, NLB
- `application` - Application servers
- `transit` - Transit Gateway attachments

---

## Route Table Strategy

### Public Route Table
- **Routes to**: Internet Gateway
- **Used by**: Public subnets
- **Enables**: Inbound/outbound internet access

### Private Route Table  
- **Routes to**: NAT Gateway (added by NAT Gateway module)
- **Used by**: Private subnets
- **Enables**: Outbound internet access only

---

## Integration with Other Modules

### Internet Gateway Module
```hcl
module "igw" {
  source = "./modules/network/internet_gateway"
  
  vpc_id               = module.vpc.vpc_id
  public_route_table_id = module.subnets.public_route_table_id
  # ...
}
```

### NAT Gateway Module
```hcl
module "nat" {
  source = "./modules/network/nat_gateway"
  
  public_subnet_ids     = module.subnets.public_subnet_ids
  private_route_table_id = module.subnets.private_route_table_id
  # ...
}
```

### EKS Module
```hcl
module "eks" {
  source = "./modules/compute/eks"
  
  subnet_ids = module.subnets.private_subnet_ids
  # OR use by purpose:
  # subnet_ids = module.subnets.subnets_by_purpose["eks"]
  # ...
}
```

---

## Validation

The module includes built-in validation:
- ✅ At least one subnet must be configured
- ✅ Tier must be "public" or "private"
- ✅ All CIDR blocks must be valid notation
- ✅ Workspace, environment, and region are required

---

## Testing

```bash
cd infrastructure/terraform/modules/network/subnet
terraform init
terraform validate
```

---

## Changelog

### Version 1.0.0 (Initial - Forge)
- Migrated from cloud-platform-features subnet module
- Added customer context support (customer_id, customer_name)
- Simplified VPC dependency (uses vpc_id variable instead of remote state)
- Enhanced outputs (13 outputs vs 10 in original)
- Added purpose-based grouping outputs
- Removed provider configuration (follows Terraform best practices)
- Improved validation and error messages
- Comprehensive documentation with 2 complete examples

---

## Authors

**MOAI Engineering - Platform Team**

**Source**: Adapted from `cloud-platform-features/iac/aws/terraform/modules/network/subnet/`

---

## License

Internal use only - MOAI Engineering
