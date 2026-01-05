# Internet Gateway Module

**Family:** Network  
**Priority:** P0 (MVP Critical)  
**Dependencies:** VPC, Subnet modules  
**Used By:** Public subnets for internet connectivity

## Overview

The Internet Gateway module creates an AWS Internet Gateway and attaches it to a VPC, enabling internet connectivity for public subnets. It also adds a default route (0.0.0.0/0) to the public route table.

## Features

- ✅ **Single IGW per VPC** - Creates one Internet Gateway per VPC (AWS limit)
- ✅ **Automatic routing** - Adds default route to public route table
- ✅ **Customer-aware naming** - IGW names based on architecture type
- ✅ **Customer-aware tagging** - Supports cost allocation by customer
- ✅ **Multi-architecture support** - Shared, dedicated local, dedicated regional

## Module Structure

```
internet_gateway/
├── main.tf          # IGW resource and default route
├── variables.tf     # Input variables (9 total)
├── outputs.tf       # IGW ID, ARN, summary (9 outputs)
├── locals.tf        # Naming and tagging logic
├── versions.tf      # Terraform and provider versions
├── backend.tf       # S3 backend (commented)
└── README.md        # This file
```

## Usage

### Example 1: Shared Forge Infrastructure

```hcl
module "forge_igw" {
  source = "./modules/network/internet_gateway"

  # VPC and Route Table
  vpc_id                 = module.forge_vpc.vpc_id
  vpc_name               = module.forge_vpc.vpc_name
  public_route_table_id  = module.forge_subnets.route_table_ids["public"]

  # Infrastructure context
  workspace         = "production"
  environment       = "prod"
  aws_region        = "us-east-1"
  architecture_type = "shared"
}
```

**Result:**
- IGW Name: `forge-production-vpc-igw`
- Default route: `0.0.0.0/0` → IGW in public route table
- Tags: Base tags only (no customer tags)

### Example 2: Customer Dedicated VPC

```hcl
module "customer_igw" {
  source = "./modules/network/internet_gateway"

  # VPC and Route Table
  vpc_id                 = module.customer_vpc.vpc_id
  vpc_name               = module.customer_vpc.vpc_name
  public_route_table_id  = module.customer_subnets.route_table_ids["public"]

  # Infrastructure context
  workspace         = "production"
  environment       = "prod"
  aws_region        = "us-east-1"

  # Customer context
  customer_id       = "550e8400-e29b-41d4-a716-446655440000"
  customer_name     = "sanofi"
  architecture_type = "dedicated_local"
  plan_tier         = "pro"
}
```

**Result:**
- IGW Name: `sanofi-us-east-1-igw`
- Default route: `0.0.0.0/0` → IGW in public route table
- Tags: Base tags + customer tags (CustomerId, CustomerName, PlanTier)

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `vpc_id` | string | Yes | - | VPC ID where IGW will be attached |
| `vpc_name` | string | Yes | - | VPC name for IGW naming |
| `public_route_table_id` | string | Yes | - | Public route table ID for default route |
| `workspace` | string | Yes | - | Workspace (production/staging/development) |
| `environment` | string | Yes | - | Environment (prod/staging/dev) |
| `aws_region` | string | Yes | - | AWS region |
| `customer_id` | string | No | null | Customer UUID |
| `customer_name` | string | No | null | Customer name |
| `architecture_type` | string | No | "shared" | shared/dedicated_local/dedicated_regional |
| `plan_tier` | string | No | null | Customer plan tier |
| `common_tags` | map(string) | No | {} | Additional tags |

## Outputs

| Name | Description |
|------|-------------|
| `internet_gateway_id` | IGW ID |
| `internet_gateway_arn` | IGW ARN |
| `vpc_id` | VPC ID |
| `public_route_table_id` | Public route table ID |
| `default_route_id` | Default route ID |
| `customer_id` | Customer ID (null for shared) |
| `customer_name` | Customer name (null for shared) |
| `architecture_type` | Architecture type |
| `internet_gateway_summary` | Configuration summary |

## Resource Naming

| Architecture | Example Name |
|--------------|--------------|
| Shared | `forge-production-vpc-igw` |
| Dedicated Local | `sanofi-us-east-1-igw` |
| Dedicated Regional | `acme-us-west-2-igw` |

## Tagging Strategy

### Base Tags (Always Applied)
```hcl
{
  ManagedBy   = "Terraform"
  Module      = "internet_gateway"
  Family      = "network"
  Workspace   = "production"
  Environment = "prod"
  Region      = "us-east-1"
}
```

### Customer Tags (Dedicated VPCs Only)
```hcl
{
  CustomerId       = "550e8400-e29b-41d4-a716-446655440000"
  CustomerName     = "sanofi"
  ArchitectureType = "dedicated_local"
  PlanTier         = "pro"
}
```

### IGW-Specific Tags
```hcl
{
  ResourceType = "InternetGateway"
  Purpose      = "PublicInternetAccess"
}
```

## Integration with Other Modules

### Dependency Chain
```
VPC → Subnet → Internet Gateway → NAT Gateway
```

### Required Outputs from Dependencies

**From VPC Module:**
- `vpc_id` - VPC where IGW will be attached
- `vpc_name` - For IGW naming

**From Subnet Module:**
- `route_table_ids["public"]` - Public route table for default route

### Used By (Downstream Modules)

**NAT Gateway Module:**
- Requires public subnets with internet access via IGW
- NAT instances need IGW for internet connectivity

**Application Load Balancer:**
- Public ALB needs IGW for internet-facing traffic

## AWS Limitations

- **One IGW per VPC** - AWS enforces this limit
- **Cannot detach while routes exist** - Must remove routes first
- **No data transfer charges** - IGW traffic is free (data transfer charges apply at EC2/NAT level)

## Best Practices

### 1. **Always Use with Public Subnets**
Only create IGW if you have public subnets that need internet access.

### 2. **Route Table Association**
IGW route should only be added to public route tables, not private.

### 3. **Security**
- Use Security Groups to control inbound traffic
- Use NACLs for additional subnet-level protection
- Never attach IGW routes to private subnet route tables

### 4. **High Availability**
- IGW is highly available by default (AWS managed)
- No need for multiple IGWs per VPC
- Automatically redundant across AZs

### 5. **Cost Optimization**
- IGW itself has no cost
- Data transfer OUT to internet has charges ($0.09/GB in us-east-1)
- Use CloudFront or S3 Transfer Acceleration for high-volume transfers

## Validation and Testing

### Terraform Validation
```bash
cd infrastructure/terraform/modules/network/internet_gateway
terraform init
terraform validate
```

### Test Connectivity (After Apply)
```bash
# From an EC2 instance in a public subnet
ping 8.8.8.8

# Check route table
aws ec2 describe-route-tables --route-table-ids <public_route_table_id>

# Verify IGW attachment
aws ec2 describe-internet-gateways --internet-gateway-ids <igw_id>
```

## Troubleshooting

### Issue: "No route to internet from public subnet"
**Cause:** Default route not added to route table  
**Solution:** Verify `public_route_table_id` is correct

### Issue: "IGW attachment failed"
**Cause:** VPC already has an IGW attached  
**Solution:** AWS allows only one IGW per VPC. Check existing IGWs.

### Issue: "Cannot delete IGW"
**Cause:** Routes still reference the IGW  
**Solution:** Remove routes first, then delete IGW

## Migration Notes

### Changes from Source Module

**✅ Added:**
- Customer context support (customer_id, customer_name, architecture_type, plan_tier)
- Customer-aware naming based on architecture type
- Enhanced outputs (IGW ARN, summary)
- Validation for VPC ID and route table ID

**❌ Removed:**
- `terraform_remote_state` data sources (replaced with variables)
- `create_igw` flag (module always creates IGW)
- Provider configuration (moved to root module)
- `dr_role`, `owner` variables (not needed in Forge)
- Per-subnet route tables (simplified to single public route table)

**🔄 Simplified:**
- Single IGW per VPC (source had for_each loop)
- Single default route (source had multiple route tables)
- Explicit variable dependencies instead of remote state

## State File Path

Configured in root module backend, not in this module.

**Example paths:**
- Shared: `modules/network/internet_gateway/terraform.tfstate`
- Customer: `customers/sanofi/network/internet_gateway/terraform.tfstate`

## Related Modules

- **VPC** - Provides VPC ID
- **Subnet** - Provides public route table ID
- **NAT Gateway** - Uses IGW for NAT instance internet access
- **ALB** - Uses IGW for internet-facing load balancers

## Version History

- **v1.0.0** - Initial Forge implementation
  - Customer-centric architecture
  - Simplified single IGW approach
  - Explicit variable dependencies

## References

- [AWS Internet Gateway Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html)
- [Terraform aws_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway)
- [Terraform aws_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route)
