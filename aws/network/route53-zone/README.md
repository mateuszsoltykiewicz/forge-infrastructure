# Route 53 Hosted Zone Module

Terraform module for creating and managing AWS Route 53 hosted zones in the Forge platform. This module provides DNS management for public and private domains with support for DNSSEC, query logging, and multi-VPC associations.

## Features

- **Public Hosted Zones**: Internet-facing DNS for public domains
- **Private Hosted Zones**: Internal DNS for VPC resources
- **DNSSEC Support**: Cryptographic signing for DNS security
- **Query Logging**: CloudWatch Logs integration for DNS queries
- **Multi-VPC Associations**: Associate private zones with multiple VPCs
- **Reusable Delegation Sets**: Consistent nameservers across zones
- **Customer-Aware Tagging**: Support for shared and dedicated architectures

## Usage

### Example 1: Public Hosted Zone

```hcl
module "public_zone" {
  source = "../../modules/network/route53-zone"

  # Customer context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"
  environment       = "production"
  region            = "us-east-1"

  # Zone configuration
  domain_name = "forge.example.com"
  zone_type   = "public"
  comment     = "Public DNS zone for Forge platform"

  tags = {
    Purpose = "public-dns"
  }
}
```

### Example 2: Private Hosted Zone for VPC

```hcl
module "private_zone" {
  source = "../../modules/network/route53-zone"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  # Private zone configuration
  domain_name = "internal.forge.local"
  zone_type   = "private"
  comment     = "Private DNS zone for internal services"

  # VPC association
  vpc_id     = module.vpc.vpc_id
  vpc_region = var.region

  tags = {
    Purpose = "internal-dns"
  }
}
```

### Example 3: Private Zone with Multiple VPC Associations

```hcl
module "multi_vpc_zone" {
  source = "../../modules/network/route53-zone"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = "us-east-1"

  domain_name = "shared.internal"
  zone_type   = "private"

  # Primary VPC (us-east-1)
  vpc_id     = module.vpc_us_east_1.vpc_id
  vpc_region = "us-east-1"

  # Additional VPCs (multi-region)
  additional_vpc_associations = [
    {
      vpc_id     = module.vpc_us_west_2.vpc_id
      vpc_region = "us-west-2"
    },
    {
      vpc_id     = module.vpc_eu_west_1.vpc_id
      vpc_region = "eu-west-1"
    }
  ]

  tags = {
    Purpose = "multi-region-dns"
  }
}
```

### Example 4: Public Zone with DNSSEC

```hcl
# Create KMS key for DNSSEC signing
module "dnssec_kms_key" {
  source = "../../modules/security/kms"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = "us-east-1"

  key_description = "KMS key for Route 53 DNSSEC signing"
  key_usage       = "SIGN_VERIFY"
  key_spec        = "ECC_NIST_P256"

  # Allow Route 53 service to use the key
  custom_key_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Route 53 DNSSEC Service"
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign",
          "kms:Verify"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = {
    Purpose = "dnssec-signing"
  }
}

# Create hosted zone with DNSSEC
module "dnssec_zone" {
  source = "../../modules/network/route53-zone"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = "us-east-1"

  domain_name = "secure.forge.com"
  zone_type   = "public"

  # Enable DNSSEC
  enable_dnssec = true
  kms_key_id    = module.dnssec_kms_key.key_arn

  tags = {
    Purpose = "secure-dns"
    DNSSEC  = "enabled"
  }
}
```

### Example 5: Zone with Query Logging

```hcl
# Create CloudWatch Log Group
resource "aws_cloudwatch_log_group" "route53_queries" {
  name              = "/aws/route53/forge-production"
  retention_in_days = 30

  tags = {
    Purpose = "dns-query-logs"
  }
}

# Create IAM policy for Route 53 to write to CloudWatch Logs
data "aws_iam_policy_document" "route53_query_logging_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["${aws_cloudwatch_log_group.route53_queries.arn}:*"]

    principals {
      type        = "Service"
      identifiers = ["route53.amazonaws.com"]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "route53_query_logging" {
  policy_name     = "route53-query-logging"
  policy_document = data.aws_iam_policy_document.route53_query_logging_policy.json
}

# Create hosted zone with query logging
module "logged_zone" {
  source = "../../modules/network/route53-zone"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  domain_name = "api.forge.com"
  zone_type   = "public"

  # Enable query logging
  enable_query_logging = true
  query_log_group_arn  = aws_cloudwatch_log_group.route53_queries.arn

  depends_on = [aws_cloudwatch_log_resource_policy.route53_query_logging]

  tags = {
    Purpose = "api-dns"
    Logging = "enabled"
  }
}
```

### Example 6: Subdomain Zone with Delegation

```hcl
# Parent zone (example.com)
module "parent_zone" {
  source = "../../modules/network/route53-zone"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  domain_name = "example.com"
  zone_type   = "public"

  tags = {
    Purpose = "parent-zone"
  }
}

# Subdomain zone (api.example.com)
module "subdomain_zone" {
  source = "../../modules/network/route53-zone"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = var.environment
  region            = var.region

  domain_name = "api.example.com"
  zone_type   = "public"

  tags = {
    Purpose    = "subdomain-zone"
    ParentZone = "example.com"
  }
}

# Create NS record in parent zone for delegation
resource "aws_route53_record" "subdomain_delegation" {
  zone_id = module.parent_zone.zone_id
  name    = "api.example.com"
  type    = "NS"
  ttl     = 172800  # 2 days

  records = module.subdomain_zone.name_servers
}
```

### Example 7: Development Environment Private Zone

```hcl
module "dev_private_zone" {
  source = "../../modules/network/route53-zone"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = "shared"
  plan_tier         = "platform"
  environment       = "development"
  region            = "us-east-1"

  domain_name = "dev.forge.internal"
  zone_type   = "private"
  comment     = "Development environment internal DNS"

  vpc_id     = module.dev_vpc.vpc_id
  vpc_region = "us-east-1"

  # Allow destruction even with records (dev environment)
  force_destroy = true

  tags = {
    Purpose     = "development-dns"
    Environment = "dev"
  }
}
```

### Example 8: Customer-Specific Zone (Dedicated Architecture)

```hcl
module "customer_zone" {
  source = "../../modules/network/route53-zone"

  # Customer-specific configuration
  customer_id       = "123e4567-e89b-12d3-a456-426614174000"
  customer_name     = "acme-corp"
  architecture_type = "dedicated_vpc"
  plan_tier         = "enterprise"
  environment       = "production"
  region            = "us-east-1"

  # Customer-owned domain
  domain_name = "acme-corp.com"
  zone_type   = "public"
  comment     = "Primary DNS zone for Acme Corp"

  tags = {
    Customer    = "acme-corp"
    Criticality = "high"
    Purpose     = "customer-primary-dns"
  }
}
```

## Hosted Zone Types

### Public Hosted Zones

**Use Cases**:
- Internet-facing websites and APIs
- Email (MX records)
- Domain verification (TXT records)
- CDN configurations (CNAME records)

**Characteristics**:
- Resolves from anywhere on the internet
- Uses Route 53 public nameservers
- Supports DNSSEC
- $0.50 per hosted zone per month
- $0.40 per million queries (first 1 billion)

### Private Hosted Zones

**Use Cases**:
- Internal service discovery (e.g., `database.internal`, `cache.internal`)
- Microservices communication
- EKS service endpoints
- VPC resource naming

**Characteristics**:
- Only resolves within associated VPCs
- Not accessible from the internet
- Supports multi-VPC associations
- $0.50 per hosted zone per month
- Free queries from within VPC

## DNSSEC (DNS Security Extensions)

### What is DNSSEC?

DNSSEC cryptographically signs DNS records to prevent:
- **DNS Spoofing**: Attackers redirecting traffic
- **Cache Poisoning**: Injecting fraudulent DNS data
- **Man-in-the-Middle Attacks**: Intercepting DNS queries

### DNSSEC Requirements

1. **KMS Key**: ECC_NIST_P256 key for signing
2. **Public Zone**: DNSSEC only works with public hosted zones
3. **Domain Registrar Support**: Your registrar must support DNSSEC
4. **DS Record**: Must be added to parent zone/registrar

### DNSSEC Setup Workflow

```hcl
# 1. Create KMS key for DNSSEC
module "dnssec_key" {
  source    = "../../modules/security/kms"
  key_usage = "SIGN_VERIFY"
  key_spec  = "ECC_NIST_P256"
}

# 2. Create hosted zone with DNSSEC
module "zone" {
  source        = "../../modules/network/route53-zone"
  enable_dnssec = true
  kms_key_id    = module.dnssec_key.key_arn
}

# 3. Get DS record from output
output "ds_record" {
  value = module.zone.key_signing_key.ds_record
}

# 4. Add DS record to parent zone or domain registrar
# (Manual step at your domain registrar)
```

### DS Record Example

```
example.com. 3600 IN DS 12345 13 2 1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF
```

## Query Logging

### What is Query Logging?

Query logging captures:
- Query timestamp
- Query name (e.g., `api.example.com`)
- Query type (A, AAAA, CNAME, etc.)
- Response code
- Query protocol (UDP/TCP)
- Edge location
- Resolver IP

### Use Cases

- **Security**: Detect DNS-based attacks (DGA, tunneling)
- **Troubleshooting**: Debug DNS resolution issues
- **Analytics**: Understand traffic patterns
- **Compliance**: Meet audit requirements

### Query Log Format

```json
{
  "version": "1.100000",
  "account_id": "123456789012",
  "region": "us-east-1",
  "vpc_id": "vpc-12345678",
  "query_timestamp": "2025-11-23T10:30:45Z",
  "query_name": "api.forge.com.",
  "query_type": "A",
  "query_class": "IN",
  "rcode": "NOERROR",
  "answers": [
    {"Rdata": "192.0.2.1", "Type": "A", "Class": "IN"}
  ],
  "srcaddr": "10.0.1.50",
  "srcport": "54321",
  "transport": "UDP",
  "srcids": {
    "instance": "i-0123456789abcdef0"
  }
}
```

## Multi-VPC Associations

### Why Associate Multiple VPCs?

- **Shared Services**: Central DNS zone for multiple VPCs
- **Multi-Region**: Same domain across regions
- **Hybrid Cloud**: On-premises + AWS VPCs
- **Microservices**: Service discovery across VPC boundaries

### Cross-Account VPC Associations

```hcl
# Account A: Create hosted zone
module "shared_zone" {
  source      = "../../modules/network/route53-zone"
  domain_name = "shared.internal"
  zone_type   = "private"
  vpc_id      = module.vpc_account_a.vpc_id
}

# Account B: Authorize VPC association
resource "aws_route53_vpc_association_authorization" "account_b" {
  provider = aws.account_a  # Zone owner account

  zone_id = module.shared_zone.zone_id
  vpc_id  = module.vpc_account_b.vpc_id
}

# Account B: Associate VPC with zone
resource "aws_route53_zone_association" "account_b" {
  provider = aws.account_b  # VPC owner account

  zone_id = module.shared_zone.zone_id
  vpc_id  = module.vpc_account_b.vpc_id

  depends_on = [aws_route53_vpc_association_authorization.account_b]
}
```

## Integration with Other Modules

### VPC Module (Private Zones)

```hcl
module "vpc" {
  source = "../../modules/network/vpc"
  # ... VPC configuration ...
}

module "private_zone" {
  source = "../../modules/network/route53-zone"
  
  zone_type = "private"
  vpc_id    = module.vpc.vpc_id
  # ... other configuration ...
}
```

### KMS Module (DNSSEC)

```hcl
module "kms" {
  source    = "../../modules/security/kms"
  key_usage = "SIGN_VERIFY"
  key_spec  = "ECC_NIST_P256"
  # ... KMS configuration ...
}

module "zone" {
  source        = "../../modules/network/route53-zone"
  enable_dnssec = true
  kms_key_id    = module.kms.key_arn
  # ... zone configuration ...
}
```

### CloudWatch Logs (Query Logging)

```hcl
resource "aws_cloudwatch_log_group" "dns_queries" {
  name              = "/aws/route53/queries"
  retention_in_days = 7
}

module "zone" {
  source               = "../../modules/network/route53-zone"
  enable_query_logging = true
  query_log_group_arn  = aws_cloudwatch_log_group.dns_queries.arn
  # ... zone configuration ...
}
```

## Best Practices

### 1. Use Private Zones for Internal Services

```hcl
# Good: Private zone for internal resources
module "internal_zone" {
  zone_type   = "private"
  domain_name = "internal.forge.local"
  vpc_id      = module.vpc.vpc_id
}

# Bad: Public zone for internal resources (security risk)
```

### 2. Enable DNSSEC for Public Zones

```hcl
# Good: DNSSEC for security
module "public_zone" {
  zone_type     = "public"
  enable_dnssec = true
  kms_key_id    = module.kms.key_arn
}
```

### 3. Use Query Logging for Production Zones

```hcl
# Good: Monitor DNS queries in production
module "production_zone" {
  enable_query_logging = true
  query_log_group_arn  = aws_cloudwatch_log_group.dns.arn
}
```

### 4. Delegate Subdomains

```hcl
# Good: Separate zones for different services
# example.com (parent)
# api.example.com (delegated subdomain)
# www.example.com (delegated subdomain)

# Better management and isolation
```

### 5. Use Descriptive Comments

```hcl
# Good: Clear purpose
comment = "Production API zone with DNSSEC and query logging"

# Bad: Generic comment
comment = "DNS zone"
```

### 6. Tag for Cost Allocation

```hcl
tags = {
  CostCenter  = "engineering"
  Application = "forge-platform"
  Environment = "production"
  Team        = "platform-team"
}
```

## Troubleshooting

### Zone Not Resolving

**Public Zones**:
```bash
# Verify nameservers at registrar match Route 53
dig NS example.com

# Test against Route 53 nameservers
dig @ns-123.awsdns-45.com example.com
```

**Private Zones**:
```bash
# From EC2 instance in associated VPC
nslookup internal.forge.local

# Check VPC DNS settings
aws ec2 describe-vpc-attribute --vpc-id vpc-xxx --attribute enableDnsHostnames
aws ec2 describe-vpc-attribute --vpc-id vpc-xxx --attribute enableDnsSupport

# Both should be true
```

### DNSSEC Validation Failing

```bash
# Check DNSSEC status
dig +dnssec example.com

# Verify DS record at parent
dig +dnssec DS example.com

# Check key signing key status
aws route53 get-dnssec --hosted-zone-id Z123456
```

### Query Logging Not Working

```bash
# Verify CloudWatch Logs policy
aws logs describe-resource-policies

# Check log group exists
aws logs describe-log-groups --log-group-name-prefix "/aws/route53"

# Verify query log configuration
aws route53 list-query-logging-configs --hosted-zone-id Z123456
```

### VPC Association Failed

```bash
# Check VPC DNS support
aws ec2 describe-vpc-attribute --vpc-id vpc-xxx --attribute enableDnsSupport

# Verify VPC exists
aws ec2 describe-vpcs --vpc-ids vpc-xxx

# Check existing associations
aws route53 list-vpc-association-authorizations --hosted-zone-id Z123456
```

## Cost Optimization

### Hosted Zone Costs

- **Hosted Zones**: $0.50/month per zone
- **Queries (Public)**: $0.40/million (first 1 billion)
- **Queries (Private)**: Free from VPC
- **Query Logging**: CloudWatch Logs ingestion costs
- **DNSSEC**: No additional cost (KMS key costs apply)

### Recommendations

**Consolidate Zones**:
```hcl
# Instead of multiple zones:
# api.example.com (zone)
# web.example.com (zone)
# admin.example.com (zone)

# Use one zone with records:
# example.com (zone)
#   - api.example.com (A record)
#   - web.example.com (A record)
#   - admin.example.com (A record)

# Savings: $1.00/month
```

**Use Private Zones for Internal Traffic**:
```hcl
# Free queries from VPC vs $0.40/million for public zones
```

**Set Appropriate TTLs**:
```hcl
# Higher TTL = fewer queries = lower costs
# Use 300s (5 min) for dynamic content
# Use 3600s (1 hour) for static content
# Use 86400s (1 day) for rarely changing content
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
| domain_name | Domain name for the hosted zone | `string` | n/a | yes |
| zone_type | Type of hosted zone (public or private) | `string` | `"public"` | no |
| comment | Comment for the hosted zone | `string` | `""` | no |
| vpc_id | VPC ID for private zones | `string` | `null` | no |
| vpc_region | VPC region | `string` | `null` | no |
| additional_vpc_associations | Additional VPCs to associate | `list(object)` | `[]` | no |
| enable_dnssec | Enable DNSSEC signing | `bool` | `false` | no |
| kms_key_id | KMS key ID for DNSSEC | `string` | `null` | no |
| enable_query_logging | Enable query logging | `bool` | `false` | no |
| query_log_group_arn | CloudWatch Log Group ARN | `string` | `null` | no |
| delegation_set_id | Reusable delegation set ID | `string` | `null` | no |
| force_destroy | Force destroy zone with records | `bool` | `false` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| zone_id | ID of the hosted zone |
| zone_arn | ARN of the hosted zone |
| zone_name | Name of the hosted zone |
| name_servers | List of nameservers |
| primary_name_server | Primary nameserver |
| zone_type | Type of hosted zone |
| comment | Comment for the zone |
| primary_vpc_id | Primary VPC ID (private zones) |
| primary_vpc_region | Primary VPC region |
| additional_vpc_associations | Additional VPC associations |
| vpc_association_count | Total VPC associations |
| dnssec_enabled | DNSSEC status |
| dnssec_status | DNSSEC configuration ID |
| key_signing_key | Key signing key information |
| query_logging_enabled | Query logging status |
| query_log_config_id | Query logging configuration ID |
| query_log_group_arn | CloudWatch Log Group ARN |
| summary | Summary of configuration |

## References

- [AWS Route 53 Documentation](https://docs.aws.amazon.com/route53/)
- [Route 53 Hosted Zones](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-working-with.html)
- [Route 53 DNSSEC](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-configuring-dnssec.html)
- [Route 53 Query Logging](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html)
- [Route 53 Private Zones](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-private.html)
- [Route 53 Pricing](https://aws.amazon.com/route53/pricing/)
- [Terraform aws_route53_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone)
