# VPC Endpoint Module

Terraform module for creating and managing AWS VPC Endpoints in the Forge platform. This module provides private connectivity to AWS services and customer applications without requiring internet gateways, NAT devices, VPN connections, or AWS Direct Connect.

## Features

- **Three Endpoint Types**: Gateway, Interface (AWS PrivateLink), and Gateway Load Balancer
- **Gateway Endpoints**: Free endpoints for S3 and DynamoDB
- **Interface Endpoints**: PrivateLink for 100+ AWS services and custom applications
- **Private DNS**: Automatic DNS resolution for AWS service endpoints
- **Security Groups**: Network-level access control for Interface endpoints
- **IPv6 Support**: Dual-stack and IPv6-only configurations
- **Policy-Based Access**: IAM policies to restrict endpoint usage
- **Customer-Aware Naming**: Automatic naming based on shared vs dedicated architectures
- **Built-in Validation**: Ensures correct configuration for each endpoint type

## Endpoint Types Overview

### Gateway Endpoints
- **Services**: S3, DynamoDB only
- **Cost**: Free (no data processing charges)
- **Network**: Uses route tables, no ENIs created
- **DNS**: Uses public service DNS names
- **Use Case**: Cost-effective access to S3/DynamoDB

### Interface Endpoints (AWS PrivateLink)
- **Services**: 100+ AWS services (EC2, ECS, Lambda, Secrets Manager, etc.)
- **Cost**: $0.01/hour per AZ + $0.01/GB data processed
- **Network**: Creates ENIs in your subnets
- **DNS**: Private DNS names (optional)
- **Use Case**: Secure access to AWS services from private subnets

### Gateway Load Balancer Endpoints
- **Services**: Third-party security appliances
- **Cost**: Per endpoint hour + data processing
- **Network**: Creates ENIs in your subnets
- **Use Case**: Traffic inspection and security appliances

## Usage

### Example 1: S3 Gateway Endpoint (Free)

```hcl
module "s3_endpoint" {
  source = "../../modules/network/vpc-endpoint"

  # Customer context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"
  environment       = "production"
  region            = "us-east-1"

  # VPC configuration
  vpc_id = module.vpc.vpc_id

  # Endpoint configuration
  service_name  = "s3"
  endpoint_type = "Gateway"

  # Associate with route tables (private subnets)
  route_table_ids = [
    module.route_table_private_1a.route_table_id,
    module.route_table_private_1b.route_table_id,
    module.route_table_private_1c.route_table_id
  ]

  tags = {
    Purpose = "private-s3-access"
  }
}
```

### Example 2: DynamoDB Gateway Endpoint (Free)

```hcl
module "dynamodb_endpoint" {
  source = "../../modules/network/vpc-endpoint"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  vpc_id = module.vpc.vpc_id

  service_name  = "dynamodb"
  endpoint_type = "Gateway"

  route_table_ids = module.route_table_private[*].route_table_id

  tags = {
    Purpose = "private-dynamodb-access"
  }
}
```

### Example 3: EC2 Interface Endpoint with Private DNS

```hcl
module "ec2_endpoint" {
  source = "../../modules/network/vpc-endpoint"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  vpc_id = module.vpc.vpc_id

  # Interface endpoint configuration
  service_name  = "ec2"
  endpoint_type = "Interface"

  # Network configuration
  subnet_ids = [
    module.subnet_private_1a.subnet_id,
    module.subnet_private_1b.subnet_id,
    module.subnet_private_1c.subnet_id
  ]

  security_group_ids = [
    module.security_group_vpc_endpoints.security_group_id
  ]

  # Enable private DNS (allows using ec2.us-east-1.amazonaws.com)
  private_dns_enabled = true

  tags = {
    Purpose = "private-ec2-api-access"
  }
}
```

### Example 4: Secrets Manager Interface Endpoint

```hcl
module "secretsmanager_endpoint" {
  source = "../../modules/network/vpc-endpoint"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  vpc_id = module.vpc.vpc_id

  service_name  = "secretsmanager"
  endpoint_type = "Interface"

  subnet_ids = var.private_subnet_ids

  security_group_ids = [
    module.security_group_vpc_endpoints.security_group_id
  ]

  private_dns_enabled = true

  tags = {
    Purpose     = "private-secrets-access"
    Criticality = "high"
  }
}
```

### Example 5: ECR Endpoints (API + Docker)

```hcl
# ECR API endpoint
module "ecr_api_endpoint" {
  source = "../../modules/network/vpc-endpoint"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  vpc_id = module.vpc.vpc_id

  service_name  = "ecr.api"
  endpoint_type = "Interface"

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [module.security_group_vpc_endpoints.security_group_id]
  private_dns_enabled = true

  tags = {
    Purpose = "ecr-api-access"
  }
}

# ECR Docker endpoint
module "ecr_dkr_endpoint" {
  source = "../../modules/network/vpc-endpoint"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  vpc_id = module.vpc.vpc_id

  service_name  = "ecr.dkr"
  endpoint_type = "Interface"

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [module.security_group_vpc_endpoints.security_group_id]
  private_dns_enabled = true

  tags = {
    Purpose = "ecr-docker-access"
  }
}
```

### Example 6: ECS Endpoints (ECS Agent + Telemetry)

```hcl
# ECS Agent endpoint
module "ecs_endpoint" {
  source = "../../modules/network/vpc-endpoint"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  vpc_id = module.vpc.vpc_id

  service_name  = "ecs"
  endpoint_type = "Interface"

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [module.security_group_vpc_endpoints.security_group_id]
  private_dns_enabled = true

  tags = {
    Purpose = "ecs-agent-access"
  }
}

# ECS Telemetry endpoint
module "ecs_telemetry_endpoint" {
  source = "../../modules/network/vpc-endpoint"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  vpc_id = module.vpc.vpc_id

  service_name  = "ecs-telemetry"
  endpoint_type = "Interface"

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [module.security_group_vpc_endpoints.security_group_id]
  private_dns_enabled = true

  tags = {
    Purpose = "ecs-telemetry"
  }
}
```

### Example 7: Lambda Interface Endpoint

```hcl
module "lambda_endpoint" {
  source = "../../modules/network/vpc-endpoint"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  vpc_id = module.vpc.vpc_id

  service_name  = "lambda"
  endpoint_type = "Interface"

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [module.security_group_vpc_endpoints.security_group_id]
  private_dns_enabled = true

  tags = {
    Purpose = "lambda-api-access"
  }
}
```

### Example 8: S3 with Access Policy Restriction

```hcl
# Create IAM policy document
data "aws_iam_policy_document" "s3_endpoint_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::forge-production-*",
      "arn:aws:s3:::forge-production-*/*"
    ]
  }
}

module "s3_endpoint_restricted" {
  source = "../../modules/network/vpc-endpoint"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  vpc_id = module.vpc.vpc_id

  service_name  = "s3"
  endpoint_type = "Gateway"

  route_table_ids = var.private_route_table_ids

  # Restrict to specific buckets
  policy = data.aws_iam_policy_document.s3_endpoint_policy.json

  tags = {
    Purpose = "restricted-s3-access"
  }
}
```

### Example 9: PrivateLink Service Endpoint (Custom Application)

```hcl
module "privatelink_endpoint" {
  source = "../../modules/network/vpc-endpoint"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  vpc_id = module.vpc.vpc_id

  # Custom PrivateLink service
  service_name  = "com.amazonaws.vpce.us-east-1.vpce-svc-0123456789abcdef0"
  endpoint_type = "Interface"

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [module.security_group_vpc_endpoints.security_group_id]
  
  # Auto-accept the connection
  auto_accept = true

  tags = {
    Purpose     = "partner-service-access"
    Application = "third-party-api"
  }
}
```

### Example 10: Dual-Stack IPv6 Endpoint

```hcl
module "s3_ipv6_endpoint" {
  source = "../../modules/network/vpc-endpoint"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  vpc_id = module.vpc.vpc_id

  service_name  = "s3"
  endpoint_type = "Interface"  # Interface endpoint for IPv6 support

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [module.security_group_vpc_endpoints.security_group_id]
  
  # Dual-stack configuration
  ip_address_type = "dualstack"
  
  dns_options = {
    dns_record_ip_type = "dualstack"
  }

  tags = {
    Purpose = "ipv6-s3-access"
  }
}
```

### Example 11: Multiple Endpoints for EKS Cluster

```hcl
# Required VPC endpoints for fully private EKS cluster
locals {
  eks_endpoints = {
    ec2 = {
      service_name = "ec2"
      description  = "EC2 API access for EKS nodes"
    }
    ecr_api = {
      service_name = "ecr.api"
      description  = "ECR API access for pulling images"
    }
    ecr_dkr = {
      service_name = "ecr.dkr"
      description  = "ECR Docker registry access"
    }
    s3 = {
      service_name = "s3"
      description  = "S3 access for ECR image layers"
      type         = "Gateway"
    }
    logs = {
      service_name = "logs"
      description  = "CloudWatch Logs for container logs"
    }
    sts = {
      service_name = "sts"
      description  = "STS for IAM role assumption (IRSA)"
    }
    elasticloadbalancing = {
      service_name = "elasticloadbalancing"
      description  = "ELB API for ALB/NLB creation"
    }
    autoscaling = {
      service_name = "autoscaling"
      description  = "Auto Scaling for node groups"
    }
  }
}

module "eks_vpc_endpoints" {
  source = "../../modules/network/vpc-endpoint"

  for_each = local.eks_endpoints

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  vpc_id = module.vpc.vpc_id

  service_name  = each.value.service_name
  endpoint_type = lookup(each.value, "type", "Interface")

  # Gateway endpoints (S3)
  route_table_ids = lookup(each.value, "type", "Interface") == "Gateway" ? (
    var.private_route_table_ids
  ) : null

  # Interface endpoints (all others)
  subnet_ids = lookup(each.value, "type", "Interface") == "Interface" ? (
    var.private_subnet_ids
  ) : null

  security_group_ids = lookup(each.value, "type", "Interface") == "Interface" ? [
    module.security_group_vpc_endpoints.security_group_id
  ] : null

  private_dns_enabled = lookup(each.value, "type", "Interface") == "Interface" ? true : null

  tags = {
    Purpose     = "eks-private-cluster"
    Service     = each.value.service_name
    Description = each.value.description
  }
}
```

## Common AWS Service Endpoints

### Compute
- `ec2` - EC2 API
- `ecs` - ECS Agent
- `ecs-agent` - ECS Agent (regional)
- `ecs-telemetry` - ECS Telemetry
- `lambda` - Lambda API

### Container Services
- `ecr.api` - ECR API
- `ecr.dkr` - ECR Docker registry
- `ecs` - ECS control plane

### Storage
- `s3` - S3 (Gateway or Interface)
- `dynamodb` - DynamoDB (Gateway or Interface)
- `elasticfilesystem` - EFS
- `fsx` - FSx

### Database
- `rds` - RDS API
- `rds-data` - RDS Data API
- `elasticache` - ElastiCache
- `redshift` - Redshift
- `redshift-data` - Redshift Data API

### Networking
- `elasticloadbalancing` - ELB API
- `servicediscovery` - Cloud Map
- `appmesh-envoy-management` - App Mesh

### Security & Identity
- `sts` - Security Token Service
- `secretsmanager` - Secrets Manager
- `kms` - KMS
- `ssm` - Systems Manager
- `ssmmessages` - Session Manager
- `ec2messages` - SSM Agent

### Monitoring & Logs
- `logs` - CloudWatch Logs
- `monitoring` - CloudWatch Metrics
- `events` - EventBridge
- `sns` - SNS
- `sqs` - SQS

### Developer Tools
- `codecommit` - CodeCommit
- `codebuild` - CodeBuild
- `codepipeline` - CodePipeline
- `git-codecommit` - CodeCommit Git

### Application Services
- `execute-api` - API Gateway
- `email-smtp` - SES SMTP

## Security Group Requirements

For **Interface endpoints**, create a security group that allows:

```hcl
module "security_group_vpc_endpoints" {
  source = "../../modules/network/security-group"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  vpc_id = module.vpc.vpc_id

  security_group_name = "vpc-endpoints"
  description         = "Security group for VPC endpoints"

  ingress_rules = [
    {
      description = "HTTPS from VPC"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  ]

  egress_rules = [
    {
      description = "Allow all outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Purpose = "vpc-endpoints"
  }
}
```

## Private DNS

### How Private DNS Works

When `private_dns_enabled = true` for Interface endpoints:

1. **AWS creates Route 53 private hosted zone** in your VPC
2. **DNS records point to endpoint ENIs** instead of public IPs
3. **Applications use standard AWS service DNS names**:
   - `secretsmanager.us-east-1.amazonaws.com` → Endpoint ENI private IPs
   - `ec2.us-east-1.amazonaws.com` → Endpoint ENI private IPs

### Without Private DNS

You must use the endpoint-specific DNS name:
```
vpce-0123456789abcdef0-12345678.secretsmanager.us-east-1.vpce.amazonaws.com
```

### With Private DNS (Recommended)

Applications use standard AWS service DNS names:
```
secretsmanager.us-east-1.amazonaws.com
```

**Best Practice**: Always enable private DNS for seamless application integration.

## Cost Optimization

### Gateway Endpoints (Free)
- **Use for**: S3, DynamoDB
- **Cost**: $0 per hour, $0 per GB
- **Savings**: No NAT Gateway data processing fees

### Interface Endpoints (Paid)
- **Cost Structure**:
  - $0.01 per hour per AZ (e.g., 3 AZs = $0.03/hour = $21.60/month)
  - $0.01 per GB data processed
- **Break-Even Analysis**:
  ```
  NAT Gateway: $0.045/hour + $0.045/GB
  Interface Endpoint: $0.01/hour + $0.01/GB
  
  For S3 access with 1 TB/month:
  - NAT Gateway: $32.40 + $46.08 = $78.48/month
  - S3 Gateway Endpoint: $0/month ✅ Use Gateway endpoint
  
  For Secrets Manager with 10 GB/month:
  - NAT Gateway: $32.40 + $0.45 = $32.85/month
  - Interface Endpoint: $21.60 + $0.10 = $21.70/month ✅ Use Interface endpoint
  ```

### Recommendations

**Always Use Gateway Endpoints**:
- S3 (if only using S3 from within VPC)
- DynamoDB

**Use Interface Endpoints When**:
- Security requirements mandate private connectivity
- High data transfer volumes to AWS services
- Fully private subnets (no NAT Gateway)
- Compliance requirements

**Use NAT Gateway When**:
- Low data transfer volumes (<100 GB/month)
- Need internet access anyway
- Cost-sensitive workloads

## Integration with Other Modules

### VPC Module
```hcl
module "vpc" {
  source = "../../modules/network/vpc"
  # ... VPC configuration ...
}

module "s3_endpoint" {
  source = "../../modules/network/vpc-endpoint"
  
  vpc_id = module.vpc.vpc_id
  # ... endpoint configuration ...
}
```

### Route Table Module (Gateway Endpoints)
```hcl
module "route_table" {
  source = "../../modules/network/route-table"
  # ... route table configuration ...
}

module "s3_endpoint" {
  source = "../../modules/network/vpc-endpoint"
  
  endpoint_type   = "Gateway"
  route_table_ids = [module.route_table.route_table_id]
  # ... other configuration ...
}
```

### Subnet Module (Interface Endpoints)
```hcl
module "subnet_private" {
  source = "../../modules/network/subnet"
  # ... subnet configuration ...
}

module "ec2_endpoint" {
  source = "../../modules/network/vpc-endpoint"
  
  endpoint_type = "Interface"
  subnet_ids    = [module.subnet_private.subnet_id]
  # ... other configuration ...
}
```

### Security Group Module
```hcl
module "security_group_endpoints" {
  source = "../../modules/network/security-group"
  # ... security group configuration ...
}

module "endpoint" {
  source = "../../modules/network/vpc-endpoint"
  
  security_group_ids = [module.security_group_endpoints.security_group_id]
  # ... other configuration ...
}
```

## Best Practices

### 1. Use Gateway Endpoints for S3 and DynamoDB
```hcl
# Good: Free Gateway endpoint
module "s3_endpoint" {
  endpoint_type = "Gateway"
  service_name  = "s3"
}

# Acceptable but costly: Interface endpoint for S3
module "s3_endpoint_interface" {
  endpoint_type = "Interface"
  service_name  = "s3"
}
```

### 2. Deploy Interface Endpoints in Multiple AZs
```hcl
# Good: High availability across 3 AZs
subnet_ids = [
  module.subnet_private_1a.subnet_id,
  module.subnet_private_1b.subnet_id,
  module.subnet_private_1c.subnet_id
]
```

### 3. Enable Private DNS
```hcl
# Good: Seamless integration
private_dns_enabled = true

# Bad: Requires application changes
private_dns_enabled = false
```

### 4. Use Restrictive Security Groups
```hcl
# Good: Allow only HTTPS from VPC
ingress_rules = [
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
]
```

### 5. Apply IAM Policies for Least Privilege
```hcl
# Good: Restrict to specific buckets
policy = jsonencode({
  Statement = [{
    Principal = "*"
    Action    = ["s3:GetObject"]
    Resource  = "arn:aws:s3:::my-bucket/*"
  }]
})
```

### 6. Tag for Cost Allocation
```hcl
tags = {
  CostCenter  = "engineering"
  Application = "forge-platform"
  Service     = "secretsmanager"
}
```

## Troubleshooting

### Connection Timeout to AWS Service

**Check Private DNS**:
```bash
# Verify DNS resolution
nslookup secretsmanager.us-east-1.amazonaws.com

# Should return endpoint private IPs (10.x.x.x), not public IPs
```

**Check Security Group**:
```bash
# Verify security group allows HTTPS from your subnet
aws ec2 describe-security-groups --group-ids <sg-id>

# Ensure port 443 is open from your VPC CIDR
```

**Check Endpoint State**:
```bash
aws ec2 describe-vpc-endpoints --vpc-endpoint-ids <vpce-id>

# State should be "available"
```

### Private DNS Not Resolving

**Enable Private DNS**:
```hcl
private_dns_enabled = true
```

**Check VPC DNS Settings**:
```bash
aws ec2 describe-vpc-attribute --vpc-id <vpc-id> --attribute enableDnsHostnames
aws ec2 describe-vpc-attribute --vpc-id <vpc-id> --attribute enableDnsSupport

# Both should be true
```

### High Costs

**Audit Endpoint Usage**:
```bash
# List all VPC endpoints
aws ec2 describe-vpc-endpoints

# Check data transfer metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/PrivateLinkEndpoints \
  --metric-name BytesProcessed \
  --dimensions Name=VPC Endpoint Id,Value=<vpce-id> \
  --start-time 2025-11-01T00:00:00Z \
  --end-time 2025-11-23T23:59:59Z \
  --period 86400 \
  --statistics Sum
```

**Consider Gateway Endpoints**:
- Replace S3 Interface endpoints with Gateway endpoints
- Replace DynamoDB Interface endpoints with Gateway endpoints

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
| vpc_id | ID of the VPC | `string` | n/a | yes |
| service_name | AWS service name or PrivateLink service ID | `string` | n/a | yes |
| endpoint_type | Type of endpoint (Gateway, Interface, GatewayLoadBalancer) | `string` | `"Interface"` | no |
| auto_accept | Accept VPC endpoint connection | `bool` | `true` | no |
| subnet_ids | List of subnet IDs (Interface/GWLB endpoints) | `list(string)` | `[]` | no |
| security_group_ids | List of security group IDs (Interface endpoints) | `list(string)` | `[]` | no |
| private_dns_enabled | Enable private DNS (Interface endpoints) | `bool` | `true` | no |
| ip_address_type | IP address type (ipv4, dualstack, ipv6) | `string` | `"ipv4"` | no |
| route_table_ids | List of route table IDs (Gateway endpoints) | `list(string)` | `[]` | no |
| dns_options | DNS options | `object` | `{}` | no |
| policy | IAM policy document (JSON) | `string` | `null` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| endpoint_id | ID of the VPC endpoint |
| endpoint_arn | ARN of the VPC endpoint |
| endpoint_name | Name of the VPC endpoint |
| service_name | Full service name |
| endpoint_type | Type of endpoint |
| state | State of the endpoint |
| vpc_id | ID of the VPC |
| network_interface_ids | List of ENI IDs (Interface) |
| subnet_ids | List of subnet IDs |
| security_group_ids | List of security group IDs |
| private_dns_enabled | Private DNS status |
| ip_address_type | IP address type |
| dns_entries | DNS entries |
| dns_names | List of DNS names |
| route_table_ids | List of route table IDs (Gateway) |
| prefix_list_id | Prefix list ID (Gateway) |
| cidr_blocks | CIDR blocks (Gateway) |
| policy | IAM policy document |
| owner_id | AWS account ID |
| requester_managed | Requester managed status |
| summary | Summary of configuration |

## References

- [AWS VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)
- [AWS PrivateLink](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html)
- [Gateway Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html)
- [Interface Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpce-interface.html)
- [VPC Endpoint Services](https://docs.aws.amazon.com/vpc/latest/privatelink/endpoint-services-overview.html)
- [VPC Endpoint Pricing](https://aws.amazon.com/privatelink/pricing/)
- [Terraform aws_vpc_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint)
