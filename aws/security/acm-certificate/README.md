# ACM Certificate Module

Terraform module for creating and managing AWS Certificate Manager (ACM) SSL/TLS certificates with automated DNS validation via Route 53.

## Features

- **Automated DNS Validation**: Automatic validation via Route 53 (recommended)
- **Email Validation Support**: Manual validation for external DNS providers
- **Wildcard Certificates**: Support for `*.example.com` wildcard domains
- **Subject Alternative Names (SANs)**: Multiple domains on single certificate
- **Key Algorithm Selection**: RSA (2048/3072/4096) or EC (P-256/P-384) keys
- **Certificate Transparency**: Optional CT logging for public trust
- **Automatic Renewal**: ACM handles renewal ~60 days before expiration
- **Expiration Monitoring**: CloudWatch alarms for production certificates
- **Multi-Region Support**: Deploy certificates in any AWS region
- **CloudFront Support**: Certificates in us-east-1 for CloudFront distributions

## Usage

### Example 1: Basic Single Domain Certificate

```hcl
module "acm_certificate" {
  source = "../../modules/security/acm-certificate"

  # Customer Context
  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "pro"
  environment       = "production"
  region            = "us-east-1"

  # Certificate Configuration
  domain_name         = "api.example.com"
  validation_method   = "DNS"
  route53_zone_id     = "Z1234567890ABC"  # Route 53 hosted zone for example.com
  wait_for_validation = true

  tags = {
    Application = "api-gateway"
    CostCenter  = "engineering"
  }
}

# Use certificate ARN with ALB
module "alb" {
  source = "../../modules/compute/alb"
  
  https_listener = {
    enabled         = true
    certificate_arn = module.acm_certificate.certificate_arn
    ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  }
  
  # ... other configuration ...
}
```

### Example 2: Wildcard Certificate with SANs

```hcl
module "wildcard_certificate" {
  source = "../../modules/security/acm-certificate"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "enterprise"
  environment       = "production"
  region            = "us-east-1"

  # Wildcard domain + specific subdomains
  domain_name = "*.example.com"
  subject_alternative_names = [
    "example.com",           # Apex domain
    "*.api.example.com",     # Additional wildcard
    "admin.example.com"      # Specific subdomain
  ]

  validation_method   = "DNS"
  route53_zone_id     = "Z1234567890ABC"
  wait_for_validation = true

  # Use elliptic curve for better performance
  key_algorithm = "EC_prime256v1"

  tags = {
    Application = "multi-service"
    Scope       = "wildcard"
  }
}

# Output shows all covered domains
output "covered_domains" {
  value = module.wildcard_certificate.all_domain_names
  # Output: ["*.example.com", "example.com", "*.api.example.com", "admin.example.com"]
}
```

### Example 3: Multi-Region Certificates for Geolocation Routing

```hcl
# Certificate in US East (for North America ALB)
module "certificate_us_east" {
  source = "../../modules/security/acm-certificate"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "enterprise"
  environment       = "production"
  region            = "us-east-1"

  domain_name         = "app.example.com"
  validation_method   = "DNS"
  route53_zone_id     = "Z1234567890ABC"
  wait_for_validation = true
}

# Certificate in EU West (for Europe ALB)
module "certificate_eu_west" {
  source = "../../modules/security/acm-certificate"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "enterprise"
  environment       = "production"
  region            = "eu-west-1"

  domain_name         = "app.example.com"
  validation_method   = "DNS"
  route53_zone_id     = "Z1234567890ABC"
  wait_for_validation = true
}

# Certificate in Asia Pacific (for APAC ALB)
module "certificate_ap_southeast" {
  source = "../../modules/security/acm-certificate"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "enterprise"
  environment       = "production"
  region            = "ap-southeast-1"

  domain_name         = "app.example.com"
  validation_method   = "DNS"
  route53_zone_id     = "Z1234567890ABC"
  wait_for_validation = true
}

# Regional ALBs with their certificates
module "alb_us_east" {
  source = "../../modules/compute/alb"
  region = "us-east-1"
  
  https_listener = {
    enabled         = true
    certificate_arn = module.certificate_us_east.certificate_arn
  }
}

module "alb_eu_west" {
  source = "../../modules/compute/alb"
  region = "eu-west-1"
  
  https_listener = {
    enabled         = true
    certificate_arn = module.certificate_eu_west.certificate_arn
  }
}

module "alb_ap_southeast" {
  source = "../../modules/compute/alb"
  region = "ap-southeast-1"
  
  https_listener = {
    enabled         = true
    certificate_arn = module.certificate_ap_southeast.certificate_arn
  }
}

# Route 53 geolocation routing
module "route53_geolocation" {
  source = "../../modules/network/route53-record"
  
  # North America → US East
  records = {
    na = {
      zone_id = "Z1234567890ABC"
      name    = "app.example.com"
      type    = "A"
      
      routing_policy = "geolocation"
      geolocation = {
        continent = "NA"
      }
      
      alias = {
        name                   = module.alb_us_east.dns_name
        zone_id                = module.alb_us_east.zone_id
        evaluate_target_health = true
      }
    }
    
    # Europe → EU West
    eu = {
      zone_id = "Z1234567890ABC"
      name    = "app.example.com"
      type    = "A"
      
      routing_policy = "geolocation"
      geolocation = {
        continent = "EU"
      }
      
      alias = {
        name                   = module.alb_eu_west.dns_name
        zone_id                = module.alb_eu_west.zone_id
        evaluate_target_health = true
      }
    }
    
    # Asia → APAC
    as = {
      zone_id = "Z1234567890ABC"
      name    = "app.example.com"
      type    = "A"
      
      routing_policy = "geolocation"
      geolocation = {
        continent = "AS"
      }
      
      alias = {
        name                   = module.alb_ap_southeast.dns_name
        zone_id                = module.alb_ap_southeast.zone_id
        evaluate_target_health = true
      }
    }
    
    # Default fallback → US East
    default = {
      zone_id = "Z1234567890ABC"
      name    = "app.example.com"
      type    = "A"
      
      routing_policy = "geolocation"
      geolocation = {
        # No continent = default location
      }
      
      alias = {
        name                   = module.alb_us_east.dns_name
        zone_id                = module.alb_us_east.zone_id
        evaluate_target_health = true
      }
    }
  }
}
```

### Example 4: CloudFront Distribution Certificate

```hcl
# CloudFront REQUIRES certificate in us-east-1 (global region)
module "cloudfront_certificate" {
  source = "../../modules/security/acm-certificate"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "pro"
  environment       = "production"
  region            = "us-east-1"  # MUST be us-east-1 for CloudFront

  domain_name = "cdn.example.com"
  subject_alternative_names = [
    "static.example.com",
    "assets.example.com"
  ]

  validation_method   = "DNS"
  route53_zone_id     = "Z1234567890ABC"
  wait_for_validation = true

  tags = {
    Application = "cdn"
    Service     = "cloudfront"
  }
}

# CloudFront distribution using the certificate
resource "aws_cloudfront_distribution" "main" {
  # ... other configuration ...

  viewer_certificate {
    acm_certificate_arn      = module.cloudfront_certificate.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = module.cloudfront_certificate.all_domain_names
}
```

### Example 5: Manual DNS Validation (External DNS Provider)

```hcl
module "external_dns_certificate" {
  source = "../../modules/security/acm-certificate"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "basic"
  environment       = "staging"
  region            = "us-west-2"

  domain_name       = "staging.example.com"
  validation_method = "DNS"
  
  # Don't create Route 53 records (using external DNS)
  create_route53_records = false
  route53_zone_id        = null
  wait_for_validation    = false  # Can't wait without Route 53

  tags = {
    DNSProvider = "Cloudflare"
  }
}

# Get validation records to add to external DNS
output "dns_validation_records" {
  description = "Add these CNAME records to your DNS provider"
  value       = module.external_dns_certificate.domain_validation_options
}

# Output example:
# [
#   {
#     domain_name           = "staging.example.com"
#     resource_record_name  = "_abc123.staging.example.com"
#     resource_record_type  = "CNAME"
#     resource_record_value = "_xyz789.acm-validations.aws."
#   }
# ]
```

### Example 6: Elliptic Curve Certificate (Better Performance)

```hcl
module "ec_certificate" {
  source = "../../modules/security/acm-certificate"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "enterprise"
  environment       = "production"
  region            = "us-east-1"

  domain_name = "api.example.com"

  # Elliptic Curve - faster handshakes, smaller keys
  key_algorithm = "EC_prime256v1"  # Or "EC_secp384r1" for 384-bit

  validation_method   = "DNS"
  route53_zone_id     = "Z1234567890ABC"
  wait_for_validation = true

  tags = {
    KeyType     = "elliptic-curve"
    Performance = "optimized"
  }
}

# EC benefits:
# - Faster SSL/TLS handshakes
# - Smaller certificate size
# - Lower CPU usage
# - Modern cipher suites
```

### Example 7: Multi-Environment Certificates

```hcl
locals {
  environments = {
    dev = {
      domain = "dev.example.com"
      zone   = "Z1111111111111"
    }
    staging = {
      domain = "staging.example.com"
      zone   = "Z2222222222222"
    }
    production = {
      domain = "example.com"
      zone   = "Z3333333333333"
      sans   = ["www.example.com", "api.example.com"]
    }
  }
}

module "certificates" {
  source = "../../modules/security/acm-certificate"
  
  for_each = local.environments

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "pro"
  environment       = each.key
  region            = "us-east-1"

  domain_name               = each.value.domain
  subject_alternative_names = try(each.value.sans, [])
  validation_method         = "DNS"
  route53_zone_id           = each.value.zone
  wait_for_validation       = true

  tags = {
    Environment = each.key
  }
}

# Access certificates by environment
output "production_certificate_arn" {
  value = module.certificates["production"].certificate_arn
}

output "staging_certificate_arn" {
  value = module.certificates["staging"].certificate_arn
}

output "dev_certificate_arn" {
  value = module.certificates["dev"].certificate_arn
}
```

## Key Algorithm Selection

### RSA Keys (Traditional)

| Algorithm | Key Size | Use Case | Compatibility |
|-----------|----------|----------|---------------|
| `RSA_2048` | 2048 bits | **Recommended default** | Universal |
| `RSA_3072` | 3072 bits | High security requirements | Universal |
| `RSA_4096` | 4096 bits | Maximum security | Universal (slower) |
| ~~`RSA_1024`~~ | 1024 bits | **Deprecated - insecure** | ❌ Don't use |

### Elliptic Curve Keys (Modern)

| Algorithm | Equivalent RSA | Use Case | Compatibility |
|-----------|----------------|----------|---------------|
| `EC_prime256v1` | ~3072-bit RSA | **Recommended for performance** | Modern browsers |
| `EC_secp384r1` | ~7680-bit RSA | High security + performance | Modern browsers |

**Recommendation**: Use `EC_prime256v1` for production workloads (faster, smaller, equally secure).

## Validation Methods

### DNS Validation (Recommended)

```hcl
validation_method   = "DNS"
route53_zone_id     = "Z1234567890ABC"
wait_for_validation = true
```

**Advantages**:
- ✅ Fully automated with Route 53
- ✅ Supports wildcard certificates
- ✅ Works with private certificates
- ✅ No manual intervention

**Requirements**:
- Route 53 hosted zone for the domain
- Terraform has permissions to create records

### Email Validation (Manual)

```hcl
validation_method = "EMAIL"
wait_for_validation = false
```

**Advantages**:
- ✅ Works with any DNS provider
- ✅ No AWS DNS required

**Disadvantages**:
- ❌ Manual validation required
- ❌ Emails sent to domain contacts
- ❌ Certificate not usable until validated
- ❌ Cannot automate with Terraform

## Certificate Transparency Logging

```hcl
certificate_transparency_logging = true  # Recommended for public certificates
```

**What is CT Logging?**
- Public log of all issued certificates
- Helps detect misissued certificates
- Required by browsers (Chrome, Safari, Firefox)
- Recommended by AWS

**When to disable**:
- Internal/private certificates
- Compliance requirements for secrecy
- Testing/development (not public)

## Integration Examples

### ALB HTTPS Listener

```hcl
module "acm_certificate" {
  source = "../../modules/security/acm-certificate"
  
  domain_name     = "api.example.com"
  # ... configuration ...
}

module "alb" {
  source = "../../modules/compute/alb"
  
  https_listener = {
    enabled         = true
    port            = 443
    certificate_arn = module.acm_certificate.certificate_arn
    ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"  # TLS 1.3 + 1.2
    target_group_key = "api"
  }
  
  http_listener = {
    enabled        = true
    port           = 80
    redirect_https = true  # Force HTTPS
  }
}
```

### API Gateway Custom Domain

```hcl
module "acm_certificate" {
  source = "../../modules/security/acm-certificate"
  
  domain_name = "api.example.com"
  region      = "us-east-1"  # Must match API Gateway region
  # ... configuration ...
}

resource "aws_api_gateway_domain_name" "api" {
  domain_name              = module.acm_certificate.domain_name
  regional_certificate_arn = module.acm_certificate.certificate_arn
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "api" {
  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  domain_name = aws_api_gateway_domain_name.api.domain_name
}
```

### CloudFront Distribution

```hcl
module "acm_certificate" {
  source = "../../modules/security/acm-certificate"
  
  domain_name = "cdn.example.com"
  region      = "us-east-1"  # MUST be us-east-1 for CloudFront
  # ... configuration ...
}

resource "aws_cloudfront_distribution" "cdn" {
  # ... other configuration ...

  aliases = [module.acm_certificate.domain_name]

  viewer_certificate {
    acm_certificate_arn      = module.acm_certificate.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# Route 53 alias to CloudFront
module "route53_record" {
  source = "../../modules/network/route53-record"
  
  records = {
    cdn = {
      zone_id = "Z1234567890ABC"
      name    = module.acm_certificate.domain_name
      type    = "A"
      
      alias = {
        name                   = aws_cloudfront_distribution.cdn.domain_name
        zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
        evaluate_target_health = false
      }
    }
  }
}
```

## Certificate Renewal

ACM automatically renews certificates **60 days before expiration**:

1. **Automatic Renewal**: No action required
2. **DNS Validation**: Automatic if Route 53 records exist
3. **Email Validation**: Requires manual validation
4. **Renewal Failure**: CloudWatch alarm (production only)

### Monitoring Renewal

```hcl
# CloudWatch alarm created automatically for production
resource "aws_cloudwatch_metric_alarm" "certificate_expiration" {
  count = var.environment == "production" ? 1 : 0
  
  alarm_name          = "${local.certificate_name}-expiration"
  comparison_operator = "LessThanThreshold"
  threshold           = 30  # Days before expiration
  
  # ... configuration ...
}
```

### Manual Renewal Check

```bash
# Check certificate status
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:123456789012:certificate/abc123 \
  --query 'Certificate.{Status:Status,NotAfter:NotAfter,InUseBy:InUseBy}' \
  --output table

# List all certificates
aws acm list-certificates \
  --certificate-statuses ISSUED \
  --query 'CertificateSummaryList[*].[DomainName,CertificateArn,NotAfter]' \
  --output table
```

## Troubleshooting

### Certificate Stuck in "Pending Validation"

**DNS Validation**:
```bash
# Check if Route 53 validation records exist
aws route53 list-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --query "ResourceRecordSets[?Type=='CNAME' && contains(Name, '_acm-validations')]"

# Manual validation record lookup
dig _abc123.example.com CNAME
```

**Solutions**:
1. Ensure Route 53 zone ID is correct
2. Verify domain ownership
3. Check DNS propagation (can take 5-30 minutes)
4. Ensure Route 53 zone is public for public certificates

### "Validation Timed Out"

```hcl
# Increase validation timeout
validation_timeout = "60m"  # Default is 45m
```

### Certificate Not Usable with CloudFront

**Issue**: CloudFront requires certificates in `us-east-1`

**Solution**:
```hcl
module "cloudfront_certificate" {
  source = "../../modules/security/acm-certificate"
  
  region = "us-east-1"  # Global region for CloudFront
  # ... configuration ...
}
```

### Wildcard Certificate Not Covering Apex

**Issue**: `*.example.com` does NOT match `example.com`

**Solution**: Add apex as SAN
```hcl
domain_name = "*.example.com"
subject_alternative_names = [
  "example.com"  # Apex domain
]
```

### Certificate Import from External CA

ACM supports importing certificates from external CAs:

```bash
aws acm import-certificate \
  --certificate fileb://certificate.pem \
  --private-key fileb://private-key.pem \
  --certificate-chain fileb://certificate-chain.pem \
  --tags Key=Name,Value=imported-cert
```

**Note**: Imported certificates do NOT auto-renew. Manual renewal required.

## Security Best Practices

1. **Use DNS Validation**: Automated, secure, supports wildcards
2. **Enable Certificate Transparency**: Required for public trust
3. **Use Strong Key Algorithms**: RSA 2048+ or EC prime256v1
4. **Monitor Expiration**: CloudWatch alarms for production
5. **Rotate Regularly**: Let ACM handle automatic renewal
6. **Least Privilege IAM**: Separate read vs write permissions
7. **Tag Appropriately**: Track ownership and usage
8. **Use Wildcard Sparingly**: Only when needed (broader scope = higher risk)

## Cost

ACM certificates are **FREE** when used with:
- ✅ Elastic Load Balancer (ALB, NLB, CLB)
- ✅ CloudFront
- ✅ API Gateway
- ✅ Elastic Beanstalk
- ✅ App Runner

**Charges apply**:
- ❌ Private certificates (AWS Private CA): $400/month for CA + $0.75/certificate
- ❌ Imported certificates: No direct charge, but manual renewal overhead

**Related costs**:
- Route 53 hosted zone: $0.50/month
- Route 53 queries: $0.40 per million (alias queries are FREE)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 6.9.0 |
| null | >= 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| customer_id | Unique identifier for the customer | `string` | n/a | yes |
| customer_name | Human-readable name of the customer | `string` | n/a | yes |
| environment | Environment name (dev, staging, production, test) | `string` | n/a | yes |
| region | AWS region for the certificate | `string` | n/a | yes |
| domain_name | Primary domain name for the certificate | `string` | n/a | yes |
| architecture_type | Type of architecture | `string` | `"forge"` | no |
| plan_tier | Service plan tier | `string` | `"basic"` | no |
| subject_alternative_names | Additional domain names (SANs) | `list(string)` | `[]` | no |
| validation_method | Certificate validation method (DNS or EMAIL) | `string` | `"DNS"` | no |
| validation_timeout | Timeout for certificate validation | `string` | `"45m"` | no |
| route53_zone_id | Route 53 hosted zone ID for DNS validation | `string` | `null` | no |
| create_route53_records | Whether to create Route 53 validation records | `bool` | `true` | no |
| validation_record_ttl | TTL for Route 53 validation records | `number` | `60` | no |
| key_algorithm | Certificate private key algorithm | `string` | `"RSA_2048"` | no |
| certificate_transparency_logging | Enable Certificate Transparency logging | `bool` | `true` | no |
| wait_for_validation | Wait for validation to complete | `bool` | `true` | no |
| early_renewal_duration | Duration before expiration for renewal warnings | `string` | `"720h"` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| certificate_arn | ARN of the ACM certificate |
| certificate_id | ID of the ACM certificate |
| certificate_domain_name | Primary domain name |
| certificate_status | Certificate status |
| domain_name | Primary domain name |
| subject_alternative_names | List of SANs |
| all_domain_names | All domains covered by certificate |
| is_wildcard | Whether this is a wildcard certificate |
| validation_method | Validation method used |
| validation_record_fqdns | FQDNs of validation records |
| domain_validation_options | Validation options for manual DNS |
| key_algorithm | Key algorithm used |
| alb_listener_config | Configuration for ALB HTTPS listener |
| cloudfront_config | Configuration for CloudFront |
| api_gateway_config | Configuration for API Gateway |
| certificate_summary | Complete certificate summary |

## Authors

MOAI Engineering Team

## License

Proprietary - MOAI Platform
