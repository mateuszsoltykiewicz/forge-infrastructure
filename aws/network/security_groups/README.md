# Security Groups Module

**Family:** Network  
**Priority:** P0 (MVP Critical)  
**Dependencies:** VPC module  
**Used By:** EKS, RDS, ALB, NLB, ElastiCache, and all compute resources

## Overview

The Security Groups module creates AWS security groups with ingress and egress rules for Forge infrastructure components. It provides a flexible configuration interface while maintaining security best practices.

## Key Features

- ✅ **Unified Module** - Security groups + rules in one module (simpler than source)
- ✅ **Flexible Configuration** - Define any security group with custom rules
- ✅ **Predefined Templates** - Common patterns for EKS, RDS, ALB, etc.
- ✅ **Customer-aware naming** - SG names based on architecture type
- ✅ **Customer-aware tagging** - Supports cost allocation by customer
- ✅ **Multi-architecture support** - Shared, dedicated local, dedicated regional
- ✅ **VPC-scoped security** - All SGs tied to specific VPC

## Module Structure

```
security_groups/
├── main.tf          # Security group resources and rules
├── variables.tf     # Input variables
├── outputs.tf       # SG IDs, ARNs, details (6 outputs)
├── locals.tf        # Naming, tagging, rule flattening
├── versions.tf      # Terraform and provider versions
├── backend.tf       # S3 backend (commented)
└── README.md        # This file
```

## Usage Examples

### Example 1: Shared Forge Infrastructure (EKS + RDS + ALB)

```hcl
module "forge_security_groups" {
  source = "./modules/network/security_groups"

  vpc_id         = module.forge_vpc.vpc_id
  vpc_name       = module.forge_vpc.vpc_name
  vpc_cidr_block = "10.0.0.0/16"

  # Define security groups for Forge components
  security_groups = {
    # EKS Cluster Security Group
    eks_cluster = {
      description = "EKS cluster control plane"
      ingress_rules = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/16"]  # Allow from VPC
          description = "Allow HTTPS from VPC for kubectl access"
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow all outbound traffic"
        }
      ]
    }

    # EKS Node Security Group
    eks_nodes = {
      description = "EKS worker nodes"
      ingress_rules = [
        {
          from_port   = 0
          to_port     = 65535
          protocol    = "tcp"
          self        = true
          description = "Allow all traffic between nodes"
        },
        {
          from_port                = 443
          to_port                  = 443
          protocol                 = "tcp"
          source_security_group_id = null  # Will be set to eks_cluster SG ID via reference
          description              = "Allow HTTPS from control plane"
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow all outbound traffic"
        }
      ]
    }

    # RDS PostgreSQL Security Group
    rds_postgresql = {
      description = "Forge control plane database"
      ingress_rules = [
        {
          from_port                = 5432
          to_port                  = 5432
          protocol                 = "tcp"
          source_security_group_id = null  # Will be set to eks_nodes SG ID
          description              = "Allow PostgreSQL from EKS nodes"
        }
      ]
      egress_rules = []  # No outbound needed for RDS
    }

    # ALB Security Group
    alb = {
      description = "Application Load Balancer"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow HTTP from internet"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow HTTPS from internet"
        }
      ]
      egress_rules = [
        {
          from_port                = 0
          to_port                  = 65535
          protocol                 = "tcp"
          source_security_group_id = null  # Will be set to eks_nodes SG ID
          description              = "Allow traffic to EKS nodes"
        }
      ]
    }
  }

  workspace         = "production"
  environment       = "prod"
  aws_region        = "us-east-1"
  architecture_type = "shared"
}

# Update cross-references after security groups are created
resource "aws_vpc_security_group_ingress_rule" "eks_nodes_from_cluster" {
  security_group_id            = module.forge_security_groups.security_group_ids["eks_nodes"]
  referenced_security_group_id = module.forge_security_groups.security_group_ids["eks_cluster"]
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Allow HTTPS from EKS control plane"
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  security_group_id            = module.forge_security_groups.security_group_ids["rds_postgresql"]
  referenced_security_group_id = module.forge_security_groups.security_group_ids["eks_nodes"]
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Allow PostgreSQL from EKS nodes"
}
```

**Result:**
- 4 security groups created:
  - `forge-production-vpc-eks_cluster`
  - `forge-production-vpc-eks_nodes`
  - `forge-production-vpc-rds_postgresql`
  - `forge-production-vpc-alb`
- Rules configured for EKS cluster communication
- Database access restricted to EKS nodes only
- ALB accepts internet traffic, forwards to EKS nodes

### Example 2: Customer Dedicated VPC (Simplified)

```hcl
module "customer_security_groups" {
  source = "./modules/network/security_groups"

  vpc_id         = module.customer_vpc.vpc_id
  vpc_name       = module.customer_vpc.vpc_name
  vpc_cidr_block = "10.10.0.0/16"

  security_groups = {
    # Customer EKS Nodes
    eks_nodes = {
      description = "Sanofi EKS worker nodes"
      ingress_rules = [
        {
          from_port   = 0
          to_port     = 65535
          protocol    = "tcp"
          self        = true
          description = "Allow inter-node communication"
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow all outbound"
        }
      ]
    }

    # Customer Database
    database = {
      description = "Sanofi RDS database"
      ingress_rules = [
        {
          from_port   = 5432
          to_port     = 5432
          protocol    = "tcp"
          cidr_blocks = ["10.10.11.0/24", "10.10.12.0/24"]  # EKS subnets
          description = "Allow PostgreSQL from EKS subnets"
        }
      ]
      egress_rules = []
    }
  }

  customer_id       = "550e8400-e29b-41d4-a716-446655440000"
  customer_name     = "sanofi"
  architecture_type = "dedicated_local"
  plan_tier         = "pro"
  workspace         = "production"
  environment       = "prod"
  aws_region        = "us-east-1"
}
```

**Result:**
- SG Names: `sanofi-us-east-1-eks_nodes`, `sanofi-us-east-1-database`
- Customer-tagged for cost allocation
- Database restricted to EKS subnet CIDR blocks

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `vpc_id` | string | Yes | - | VPC ID where security groups will be created |
| `vpc_name` | string | Yes | - | VPC name for security group naming |
| `vpc_cidr_block` | string | Yes | - | VPC CIDR block for internal traffic rules |
| `security_groups` | map(object) | Yes | - | Map of security groups to create with rules |
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
| `security_group_ids` | Map of SG names to IDs |
| `security_group_arns` | Map of SG names to ARNs |
| `security_group_details` | Detailed info (ID, ARN, name, description, VPC) |
| `rule_counts` | Ingress/egress rule counts per SG |
| `customer_id` | Customer ID (null for shared) |
| `customer_name` | Customer name (null for shared) |
| `architecture_type` | Architecture type |
| `security_groups_summary` | Complete configuration summary |

## Security Group Configuration

### Security Group Object Structure

```hcl
{
  "sg_name" = {
    description = "Description of the security group"
    ingress_rules = [
      {
        from_port                = 443
        to_port                  = 443
        protocol                 = "tcp"
        cidr_blocks              = ["10.0.0.0/16"]  # OR
        ipv6_cidr_blocks         = ["::/0"]          # OR
        source_security_group_id = "sg-abc123"      # OR
        self                     = true              # Allow from same SG
        description              = "Rule description"
      }
    ]
    egress_rules = [
      # Same structure as ingress_rules
    ]
  }
}
```

### Rule Types

**By Source/Destination:**
- `cidr_blocks` - IPv4 CIDR blocks (e.g., `["10.0.0.0/16", "192.168.1.0/24"]`)
- `ipv6_cidr_blocks` - IPv6 CIDR blocks (e.g., `["::/0"]`)
- `source_security_group_id` - Another security group ID
- `self` - Traffic from same security group (for clustering)

**Only ONE of the above can be specified per rule.**

## Predefined Security Group Templates

### EKS Cluster Control Plane

```hcl
eks_cluster = {
  description = "EKS cluster control plane"
  ingress_rules = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
      description = "HTTPS from VPC for kubectl"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "All outbound"
    }
  ]
}
```

### EKS Worker Nodes

```hcl
eks_nodes = {
  description = "EKS worker nodes"
  ingress_rules = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      self        = true
      description = "Inter-node communication"
    },
    {
      from_port   = 1025
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
      description = "NodePort services from VPC"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "All outbound"
    }
  ]
}
```

### RDS PostgreSQL

```hcl
rds_postgresql = {
  description = "PostgreSQL database"
  ingress_rules = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["10.0.11.0/24"]  # EKS subnet
      description = "PostgreSQL from EKS"
    }
  ]
  egress_rules = []  # RDS doesn't need outbound
}
```

### ElastiCache Redis

```hcl
redis = {
  description = "ElastiCache Redis cluster"
  ingress_rules = [
    {
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_blocks = ["10.0.11.0/24"]
      description = "Redis from EKS"
    }
  ]
  egress_rules = []
}
```

### Application Load Balancer (Internet-Facing)

```hcl
alb_public = {
  description = "Public Application Load Balancer"
  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from internet"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS from internet"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
      description = "Forward to VPC targets"
    }
  ]
}
```

### Bastion Host

```hcl
bastion = {
  description = "Bastion host for SSH access"
  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["203.0.113.0/24"]  # Your office IP
      description = "SSH from office"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "All outbound"
    }
  ]
}
```

## Resource Naming

| Architecture | Example Names |
|--------------|---------------|
| Shared | `forge-production-vpc-eks_cluster`, `forge-production-vpc-rds_postgresql` |
| Dedicated Local | `sanofi-us-east-1-eks_nodes`, `sanofi-us-east-1-database` |
| Dedicated Regional | `acme-us-west-2-alb`, `acme-us-west-2-redis` |

## Tagging Strategy

### Base Tags (Always Applied)
```hcl
{
  ManagedBy   = "Terraform"
  Module      = "security_groups"
  Family      = "network"
  Workspace   = "production"
  Environment = "prod"
  Region      = "us-east-1"
  VpcId       = "vpc-abc123"
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

### Security Group-Specific Tags
```hcl
{
  Name    = "sanofi-us-east-1-eks_nodes"
  Purpose = "eks_nodes"
}
```

### Rule Tags
```hcl
{
  Name      = "eks_nodes-ingress-0"
  Direction = "ingress"
  Protocol  = "tcp"
}
```

## Best Practices

### 1. **Principle of Least Privilege**
Only allow traffic that is absolutely necessary.

```hcl
# ❌ Too permissive
ingress_rules = [{
  from_port   = 0
  to_port     = 65535
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all traffic"
}]

# ✅ Specific and secure
ingress_rules = [{
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/16"]
  description = "HTTPS from VPC only"
}]
```

### 2. **Use Security Group References**
Prefer security group references over CIDR blocks for internal traffic.

```hcl
# ✅ Better - automatically tracks EKS node IPs
ingress_rules = [{
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = "PostgreSQL from EKS nodes"
}]

# ❌ Brittle - must update if subnet CIDR changes
ingress_rules = [{
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = ["10.0.11.0/24", "10.0.12.0/24"]
  description = "PostgreSQL from EKS subnets"
}]
```

### 3. **Descriptive Rule Descriptions**
Always add meaningful descriptions to rules.

```hcl
# ✅ Clear purpose
description = "Allow HTTPS from ALB to EKS ingress controller"

# ❌ Vague
description = "Allow 443"
```

### 4. **Separate Security Groups by Purpose**
Don't reuse security groups across different components.

```hcl
# ✅ Separate SGs
eks_cluster = { ... }
eks_nodes = { ... }
rds_postgresql = { ... }

# ❌ Single SG for everything (harder to audit)
everything = { ... }
```

### 5. **Default Deny Egress for Databases**
Databases typically don't need outbound access.

```hcl
rds_postgresql = {
  description = "PostgreSQL database"
  ingress_rules = [...]
  egress_rules = []  # No outbound needed
}
```

### 6. **Use Self-Referencing for Clustering**
For clustered services (EKS nodes, Redis cluster), use `self = true`.

```hcl
ingress_rules = [{
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  self        = true
  description = "Allow inter-node communication"
}]
```

## Common Patterns

### Pattern 1: EKS Three-Tier Architecture

```hcl
security_groups = {
  alb       = { ... }  # Internet → ALB
  eks_nodes = { ... }  # ALB → EKS Nodes
  database  = { ... }  # EKS Nodes → Database
}
```

### Pattern 2: Customer Isolation

Each customer gets dedicated security groups with customer-specific tags:

```hcl
# Customer A
sanofi_eks_nodes = { ... }
sanofi_database  = { ... }

# Customer B  
acme_eks_nodes = { ... }
acme_database  = { ... }
```

### Pattern 3: Multi-Region Consistency

Use same security group names across regions:

```hcl
# us-east-1
sanofi-us-east-1-eks_nodes
sanofi-us-east-1-database

# us-west-2
sanofi-us-west-2-eks_nodes
sanofi-us-west-2-database
```

## Integration with Other Modules

### Dependency Chain
```
VPC → Security Groups → EKS, RDS, ALB, ElastiCache
```

### Required Outputs from Dependencies

**From VPC Module:**
- `vpc_id` - VPC where security groups will be created
- `vpc_name` - For security group naming
- `vpc_cidr_block` - For VPC-wide traffic rules

### Used By (Downstream Modules)

**EKS Module:**
- `security_group_ids["eks_cluster"]` - EKS control plane SG
- `security_group_ids["eks_nodes"]` - EKS worker node SG

**RDS Module:**
- `security_group_ids["rds_postgresql"]` - Database SG

**ALB Module:**
- `security_group_ids["alb"]` - Load balancer SG

**ElastiCache Module:**
- `security_group_ids["redis"]` - Redis cluster SG

## Validation and Testing

### Terraform Validation
```bash
cd infrastructure/terraform/modules/network/security_groups
terraform init
terraform validate
```

### Test Security Group Rules (After Apply)

**1. List Security Groups:**
```bash
aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=<vpc_id>" \
  --query 'SecurityGroups[*].[GroupName,GroupId]' \
  --output table
```

**2. Verify Ingress Rules:**
```bash
aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=<sg_id>" "Name=is-egress,Values=false" \
  --query 'SecurityGroupRules[*].[FromPort,ToPort,IpProtocol,CidrIpv4,Description]' \
  --output table
```

**3. Test Connectivity:**
```bash
# From EKS node to RDS
nc -zv <rds_endpoint> 5432

# From ALB to EKS service
curl -I http://<alb_dns>
```

## Troubleshooting

### Issue: "Cannot connect to RDS from EKS"
**Cause:** Security group rules not configured correctly  
**Solutions:**
1. Verify RDS SG allows ingress from EKS nodes SG
2. Check EKS nodes SG allows egress to RDS port
3. Verify subnet routing and NACLs

### Issue: "Security group rule already exists"
**Cause:** Duplicate rule definition  
**Solution:** Check for duplicate rules in ingress_rules or egress_rules arrays

### Issue: "Cannot reference security group ID"
**Cause:** Circular dependency between security groups  
**Solution:** Create SGs first, add cross-references in separate resources (see Example 1)

## Migration Notes

### Changes from Source Module

**✅ Added:**
- Unified module (security groups + rules together)
- Customer context support (customer_id, customer_name, architecture_type, plan_tier)
- Flexible security group configuration via map(object)
- Enhanced outputs (ARNs, details, rule counts, summary)
- Rule descriptions required for auditability
- Support for all rule types (CIDR, IPv6, SG references, self)

**❌ Removed:**
- Separate `security_group_rules` module (unified into one)
- `terraform_remote_state` data sources (replaced with variables)
- Provider configuration (moved to root module)
- `dr_role`, `owner` variables (not needed in Forge)
- `tier` and `purpose` separation (simplified to single `name` key)

**🔄 Simplified:**
- Single module instead of 3 separate modules (groups, rules, chaining)
- Clearer rule definition structure
- Direct SG ID outputs instead of tag-based lookups

## State File Path

Configured in root module backend, not in this module.

**Example paths:**
- Shared: `modules/network/security_groups/terraform.tfstate`
- Customer: `customers/sanofi/network/security_groups/terraform.tfstate`

## Related Modules

- **VPC** - Provides VPC ID and CIDR block
- **EKS** - Uses EKS cluster and node security groups
- **RDS** - Uses database security groups
- **ALB/NLB** - Uses load balancer security groups
- **ElastiCache** - Uses Redis security groups

## Version History

- **v1.0.0** - Initial Forge implementation
  - Unified security groups + rules module
  - Customer-centric architecture
  - Flexible configuration interface
  - Explicit variable dependencies

## References

- [AWS Security Groups Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)
- [Security Group Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [Terraform aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)
- [Terraform aws_vpc_security_group_ingress_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule)
