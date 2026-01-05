# NAT Gateway Module

**Family:** Network  
**Priority:** P0 (MVP Critical)  
**Dependencies:** VPC, Subnet, Internet Gateway modules  
**Used By:** Private subnets for internet access

## Overview

The NAT Gateway module creates AWS NAT Gateways with Elastic IPs to enable outbound internet access for resources in private subnets. It includes **hybrid error handling** for EIP capacity management with flexible deployment modes.

## Key Features

- ✅ **Hybrid EIP Error Handling** - Strict validation with optional best-effort mode
- ✅ **Flexible Deployment Modes** - HA, single, or best-effort
- ✅ **EIP Capacity Checking** - Validates available EIPs before creation
- ✅ **Existing EIP Support** - Reuse pre-allocated EIPs
- ✅ **Customer-aware naming** - NAT Gateway names based on architecture type
- ✅ **Customer-aware tagging** - Supports cost allocation by customer
- ✅ **Multi-architecture support** - Shared, dedicated local, dedicated regional
- ✅ **Route distribution** - Automatic route table management

## Module Structure

```
nat_gateway/
├── main.tf          # NAT GW, EIP resources, routes, validation
├── variables.tf     # Input variables (12 total)
├── outputs.tf       # NAT GW IDs, EIPs, capacity info (11 outputs)
├── locals.tf        # EIP calculations, naming, tagging logic
├── data.tf          # EIP usage query, Service Quotas check
├── versions.tf      # Terraform and provider versions
├── backend.tf       # S3 backend (commented)
└── README.md        # This file
```

## Deployment Modes

### 1. High Availability Mode (Recommended for Production)
Creates **one NAT Gateway per AZ** for fault tolerance.

```hcl
nat_gateway_mode = "high_availability"
# Creates NAT GW in each public subnet (one per AZ)
```

**Requirements:**
- EIPs available = Number of public subnets (typically 2-3)
- Higher cost (multiple NAT Gateways + data transfer)

**Benefits:**
- No single point of failure
- AZ-isolated traffic routing
- Continues working if one AZ fails

### 2. Single Mode (Cost Optimization)
Creates **one NAT Gateway total**, all private subnets route through it.

```hcl
nat_gateway_mode = "single"
# Creates 1 NAT GW only, regardless of AZ count
```

**Requirements:**
- 1 EIP available

**Benefits:**
- Lower cost (single NAT Gateway)
- Ideal for dev/test environments, Trial/Basic plans

**Drawbacks:**
- Single point of failure
- Cross-AZ data transfer charges
- If NAT GW AZ fails, all private subnets lose internet

### 3. Best Effort Mode (Graceful Degradation)
Creates **as many NAT Gateways as EIPs allow**, with warnings.

```hcl
nat_gateway_mode = "best_effort"
# Creates min(desired_count, available_eips) NAT Gateways
```

**Use Cases:**
- Bootstrap environment with limited EIPs
- Gradual migration (start with 1, scale to HA later)
- Temporary EIP shortage

**Behavior:**
- Succeeds even with insufficient EIPs
- Outputs warning about reduced NAT count
- Creates partial HA (e.g., 2/3 NAT Gateways)

## Usage Examples

### Example 1: Shared Forge Infrastructure (HA Mode)

```hcl
module "forge_nat_gateway" {
  source = "./modules/network/nat_gateway"

  # VPC and Subnets
  vpc_id         = module.forge_vpc.vpc_id
  vpc_name       = module.forge_vpc.vpc_name
  public_subnet_ids = module.forge_subnets.public_subnet_ids  # 3 AZs
  private_route_table_ids = [
    module.forge_subnets.route_table_ids["private"]
  ]

  # High Availability mode (creates 3 NAT GWs, 1 per AZ)
  nat_gateway_mode = "high_availability"

  # EIP management
  check_eip_quota    = true   # Query AWS for actual EIP limit
  default_eip_limit  = 5      # Fallback if API fails

  # Infrastructure context
  workspace         = "production"
  environment       = "prod"
  aws_region        = "us-east-1"
  architecture_type = "shared"
}
```

**Result:**
- 3 NAT Gateways (us-east-1a, us-east-1b, us-east-1c)
- 3 Elastic IPs allocated
- Private route table has 0.0.0.0/0 → NAT GW (round-robin)
- NAT GW Names: `forge-production-vpc-nat-1`, `forge-production-vpc-nat-2`, `forge-production-vpc-nat-3`

### Example 2: Customer Dedicated VPC (Single Mode - Cost Optimization)

```hcl
module "customer_nat_gateway" {
  source = "./modules/network/nat_gateway"

  # VPC and Subnets
  vpc_id         = module.customer_vpc.vpc_id
  vpc_name       = module.customer_vpc.vpc_name
  public_subnet_ids = module.customer_subnets.public_subnet_ids  # 2 AZs
  private_route_table_ids = [
    module.customer_subnets.route_table_ids["private"]
  ]

  # Single NAT Gateway (cost optimization for Pro plan)
  nat_gateway_mode = "single"

  # EIP management
  check_eip_quota    = false  # Don't query AWS (faster)
  default_eip_limit  = 5

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
- 1 NAT Gateway (placed in public subnet 0)
- 1 Elastic IP allocated
- Private route table has 0.0.0.0/0 → Single NAT GW
- NAT GW Name: `sanofi-us-east-1-nat-1`
- Cost: ~$33/month (vs ~$99/month for 3 NAT GWs)

### Example 3: Best Effort Mode (EIP Shortage Handling)

```hcl
module "bootstrap_nat_gateway" {
  source = "./modules/network/nat_gateway"

  vpc_id         = module.bootstrap_vpc.vpc_id
  vpc_name       = module.bootstrap_vpc.vpc_name
  public_subnet_ids = module.bootstrap_subnets.public_subnet_ids  # 3 AZs
  private_route_table_ids = [
    module.bootstrap_subnets.route_table_ids["private"]
  ]

  # Best effort mode - create as many as possible
  nat_gateway_mode = "best_effort"

  # EIP management
  check_eip_quota    = true
  default_eip_limit  = 5

  workspace         = "production"
  environment       = "prod"
  aws_region        = "us-east-1"
  architecture_type = "shared"
}
```

**Scenario:**
- Desired: 3 NAT Gateways
- Available EIPs: 2 (3 already in use)
- Result: Creates 2 NAT Gateways, outputs warning

**Output:**
```
WARNING: NAT Gateway count reduced due to EIP availability.

Requested: 3 NAT Gateways
Created: 2 NAT Gateways

This configuration is NOT highly available. For production workloads:
1. Request EIP limit increase to 3
2. Change nat_gateway_mode to "high_availability" after EIP increase
```

### Example 4: Using Existing EIPs

```hcl
# Scenario: Pre-allocate EIPs for specific IP addresses (whitelisting)

# Step 1: Allocate EIPs manually
resource "aws_eip" "customer_nat" {
  count  = 2
  domain = "vpc"

  tags = {
    Name     = "sanofi-reserved-eip-${count.index + 1}"
    Customer = "sanofi"
    Purpose  = "NAT Gateway - Whitelisted IP"
  }
}

# Step 2: Use existing EIPs in NAT module
module "customer_nat_gateway" {
  source = "./modules/network/nat_gateway"

  vpc_id                      = module.customer_vpc.vpc_id
  vpc_name                    = module.customer_vpc.vpc_name
  public_subnet_ids           = module.customer_subnets.public_subnet_ids
  private_route_table_ids     = [module.customer_subnets.route_table_ids["private"]]

  # Provide existing EIP allocation IDs
  existing_eip_allocation_ids = aws_eip.customer_nat[*].id

  # Mode doesn't matter when using existing EIPs (count determined by list length)
  nat_gateway_mode = "high_availability"

  customer_id       = "550e8400-e29b-41d4-a716-446655440000"
  customer_name     = "sanofi"
  architecture_type = "dedicated_local"
  plan_tier         = "enterprise"

  workspace         = "production"
  environment       = "prod"
  aws_region        = "us-east-1"
}
```

**Result:**
- Uses pre-allocated EIPs (customer can whitelist these IPs)
- No new EIPs created
- NAT Gateway count = length(existing_eip_allocation_ids)

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `vpc_id` | string | Yes | - | VPC ID where NAT Gateways will be created |
| `vpc_name` | string | Yes | - | VPC name for NAT Gateway naming |
| `public_subnet_ids` | list(string) | Yes | - | Public subnet IDs for NAT Gateway placement |
| `private_route_table_ids` | list(string) | Yes | - | Private route table IDs for default route |
| `nat_gateway_mode` | string | No | "high_availability" | Deployment mode (high_availability/single/best_effort) |
| `check_eip_quota` | bool | No | false | Query AWS Service Quotas for EIP limit |
| `default_eip_limit` | number | No | 5 | Default EIP limit (used when check_eip_quota=false) |
| `existing_eip_allocation_ids` | list(string) | No | null | Existing EIP allocation IDs to use |
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
| `nat_gateway_ids` | List of NAT Gateway IDs |
| `nat_gateway_count` | Actual number of NAT Gateways created |
| `nat_gateway_mode` | Deployment mode used |
| `eip_ids` | List of EIP allocation IDs |
| `eip_public_ips` | List of EIP public IP addresses |
| `eip_capacity_info` | EIP limit, usage, availability info |
| `private_route_table_ids` | Private route table IDs |
| `route_ids` | Route IDs for NAT routes |
| `deployment_status` | Deployment status and warnings |
| `customer_id` | Customer ID (null for shared) |
| `customer_name` | Customer name (null for shared) |
| `architecture_type` | Architecture type |
| `nat_gateway_summary` | Complete configuration summary |

## EIP Error Handling

### Validation Behavior by Mode

| Mode | EIP Shortage Behavior | Use Case |
|------|----------------------|----------|
| `high_availability` | ❌ **FAILS** with error message | Production (strict validation) |
| `single` | ❌ **FAILS** if < 1 EIP available | Cost-optimized (still strict) |
| `best_effort` | ✅ **SUCCEEDS**, creates partial NAT, outputs warning | Bootstrap, gradual migration |

### Error Message Example

When `nat_gateway_mode = "high_availability"` and insufficient EIPs:

```
Error: Insufficient EIPs available for NAT Gateway deployment.

Mode: high_availability
Desired NAT Gateways: 3
Available EIPs: 1
EIP Limit (from AWS API): 5
Currently in use: 4

Solutions:
1. Request EIP limit increase via AWS Service Quotas:
   https://console.aws.amazon.com/servicequotas/
2. Set nat_gateway_mode = "single" (creates 1 NAT Gateway only)
3. Set nat_gateway_mode = "best_effort" (creates 1 NAT Gateway)
4. Release unused EIPs in region us-east-1
5. Provide existing_eip_allocation_ids to reuse allocated EIPs
```

## EIP Quota Management

### Check EIP Quota from AWS

```hcl
check_eip_quota = true
```

**Requirements:**
- IAM permission: `servicequotas:GetServiceQuota`
- Slightly slower (API call to Service Quotas)

**Benefits:**
- Accurate EIP limit (reflects quota increases)
- Better error messages

### Use Default Limit

```hcl
check_eip_quota    = false
default_eip_limit  = 5  # Update if you increased quota
```

**Use When:**
- Service Quotas API not available
- Faster validation needed
- You know your EIP limit

### Increase EIP Limit

1. Go to [AWS Service Quotas Console](https://console.aws.amazon.com/servicequotas/)
2. Search for "Elastic IP addresses"
3. Request quota increase (EC2 > L-0263D0A3)
4. Wait for approval (usually instant for small increases)
5. Update `default_eip_limit` or enable `check_eip_quota`

## Resource Naming

| Architecture | Example Names |
|--------------|---------------|
| Shared | `forge-production-vpc-nat-1`, `forge-production-vpc-nat-2`, `forge-production-vpc-nat-3` |
| Dedicated Local | `sanofi-us-east-1-nat-1`, `sanofi-us-east-1-nat-2` |
| Dedicated Regional | `acme-us-west-2-nat-1`, `acme-us-west-2-nat-2` |

## Tagging Strategy

### Base Tags (Always Applied)
```hcl
{
  ManagedBy      = "Terraform"
  Module         = "nat_gateway"
  Family         = "network"
  Workspace      = "production"
  Environment    = "prod"
  Region         = "us-east-1"
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

### NAT Gateway-Specific Tags
```hcl
{
  ResourceType   = "NATGateway"
  DeploymentMode = "high_availability"
  Index          = 1
  SubnetId       = "subnet-abc123"
  EIPSource      = "created"  # or "existing"
}
```

## Cost Optimization

### NAT Gateway Pricing (us-east-1)
- **Hourly charge**: $0.045/hour (~$33/month per NAT GW)
- **Data processing**: $0.045/GB processed

### Cost by Mode

| Mode | NAT GWs | Monthly Cost | Data Processing | Total (1TB/month) |
|------|---------|--------------|-----------------|-------------------|
| Single | 1 | $33 | $45 | **$78** |
| HA (3 AZs) | 3 | $99 | $45 | **$144** |

### Recommendations by Plan Tier

| Plan | Mode | Rationale |
|------|------|-----------|
| Trial | Single | Cost optimization, acceptable for dev/test |
| Basic | Single | Lower monthly cost, suitable for small workloads |
| Pro | Single or HA | Customer choice (cost vs HA) |
| Enterprise | HA | Production SLA, fault tolerance required |

## High Availability Considerations

### Single Mode Risks
- ❌ AZ failure = complete internet outage for private subnets
- ❌ NAT Gateway failure = complete outage (rare but possible)
- ❌ Cross-AZ data transfer charges

### HA Mode Benefits
- ✅ AZ failure = only that AZ's private subnets affected
- ✅ Per-AZ isolation (no cross-AZ traffic)
- ✅ Higher throughput (distributed load)

### Best Effort Mode Warnings
- ⚠️ Creates partial HA (e.g., 2/3 NAT Gateways)
- ⚠️ Some AZs without local NAT Gateway (cross-AZ traffic)
- ⚠️ Should be temporary until EIP limit increased

## Integration with Other Modules

### Dependency Chain
```
VPC → Subnet → Internet Gateway → NAT Gateway
```

### Required Outputs from Dependencies

**From VPC Module:**
- `vpc_id` - VPC where NAT Gateway will be created
- `vpc_name` - For NAT Gateway naming

**From Subnet Module:**
- `public_subnet_ids` - Public subnets for NAT Gateway placement
- `route_table_ids["private"]` - Private route table for default route

**From Internet Gateway Module:**
- None (but IGW must exist for public subnets to have internet)

### Used By (Downstream Modules)

**Private Subnet Resources:**
- EC2 instances (software updates, package downloads)
- EKS nodes (pull container images from DockerHub, etc.)
- Lambda functions (VPC-attached)
- RDS instances (connect to external APIs)

## Validation and Testing

### Terraform Validation
```bash
cd infrastructure/terraform/modules/network/nat_gateway
terraform init
terraform validate
```

### Test Connectivity (After Apply)

**1. From EC2 in Private Subnet:**
```bash
# SSH to instance in private subnet (via bastion)
curl -I https://www.google.com
# Should succeed via NAT Gateway
```

**2. Check NAT Gateway Status:**
```bash
# Verify NAT Gateways are active
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=<vpc_id>" \
  --query 'NatGateways[*].[NatGatewayId,State,SubnetId]' \
  --output table
```

**3. Verify EIP Association:**
```bash
# Check EIP allocation
aws ec2 describe-addresses \
  --filters "Name=domain,Values=vpc" \
  --query 'Addresses[*].[AllocationId,PublicIp,AssociationId]' \
  --output table
```

**4. Test Route Tables:**
```bash
# Verify default route to NAT Gateway
aws ec2 describe-route-tables \
  --route-table-ids <private_route_table_id> \
  --query 'RouteTables[*].Routes[?DestinationCidrBlock==`0.0.0.0/0`]'
```

## Troubleshooting

### Issue: "Insufficient EIPs available"
**Cause:** Not enough EIPs to create desired NAT Gateways  
**Solutions:**
1. Request EIP limit increase via Service Quotas
2. Change to `nat_gateway_mode = "single"`
3. Change to `nat_gateway_mode = "best_effort"`
4. Release unused EIPs
5. Use `existing_eip_allocation_ids`

### Issue: "No internet from private subnet"
**Cause:** NAT Gateway not properly configured or route missing  
**Solutions:**
1. Verify NAT Gateway state is "available"
2. Check private route table has 0.0.0.0/0 → NAT GW
3. Verify public subnet has 0.0.0.0/0 → IGW
4. Check security groups allow outbound traffic
5. Verify NACLs allow return traffic

### Issue: "NAT Gateway creation failed"
**Cause:** Public subnet doesn't have internet gateway route  
**Solution:** Ensure Internet Gateway module is deployed first

### Issue: "High data transfer costs"
**Cause:** Cross-AZ traffic in single NAT mode  
**Solution:** Switch to `nat_gateway_mode = "high_availability"`

## Migration Notes

### Changes from Source Module

**✅ Added:**
- Hybrid EIP error handling (strict + best-effort modes)
- `nat_gateway_mode` variable (HA/single/best-effort)
- EIP capacity checking (`data.aws_eips`, Service Quotas)
- `existing_eip_allocation_ids` support
- Customer context support (customer_id, customer_name, architecture_type, plan_tier)
- Enhanced outputs (EIP capacity info, deployment status)
- Validation with actionable error messages
- Route distribution strategy (round-robin in HA mode)

**❌ Removed:**
- `terraform_remote_state` data sources (replaced with variables)
- Provider configuration (moved to root module)
- `dr_role`, `owner` variables (not needed in Forge)
- Per-subnet route tables (simplified to shared private route table)
- `purpose` filtering (simplified subnet selection)

**🔄 Simplified:**
- EIP and NAT Gateway resources use `count` instead of `for_each`
- Single shared private route table instead of per-subnet tables
- Clear mode selection instead of complex conditionals

## State File Path

Configured in root module backend, not in this module.

**Example paths:**
- Shared: `modules/network/nat_gateway/terraform.tfstate`
- Customer: `customers/sanofi/network/nat_gateway/terraform.tfstate`

## Related Modules

- **VPC** - Provides VPC ID
- **Subnet** - Provides public subnet IDs and private route table IDs
- **Internet Gateway** - Required for public subnet internet access
- **Security Groups** - Controls traffic to/from NAT Gateway

## Best Practices

### 1. **Use HA Mode for Production**
Always use `nat_gateway_mode = "high_availability"` for customer-facing environments.

### 2. **Request EIP Limit Increase Early**
Don't wait for deployment to discover EIP shortage. Request increases during planning.

### 3. **Use Single Mode for Non-Production**
Dev/test environments can use `nat_gateway_mode = "single"` to save costs.

### 4. **Monitor NAT Gateway Metrics**
- `BytesInFromDestination` - Traffic from internet
- `BytesOutToDestination` - Traffic to internet
- `ErrorPortAllocation` - Port exhaustion (need more NAT GWs)

### 5. **Plan for EIP Whitelisting**
If customers need to whitelist IPs, use `existing_eip_allocation_ids` with pre-allocated EIPs.

### 6. **Consider VPC Endpoints**
For AWS service access (S3, DynamoDB), use VPC endpoints instead of NAT Gateway (no cost, better performance).

## Version History

- **v1.0.0** - Initial Forge implementation
  - Hybrid EIP error handling
  - Flexible deployment modes
  - Customer-centric architecture
  - Explicit variable dependencies

## References

- [AWS NAT Gateway Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [AWS EIP Limits](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html#using-instance-addressing-limit)
- [Terraform aws_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway)
- [Terraform aws_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip)
- [AWS Service Quotas](https://docs.aws.amazon.com/servicequotas/latest/userguide/intro.html)
