# WAF Web ACL Module

Terraform module for creating and managing AWS WAF (Web Application Firewall) Web ACLs with comprehensive protection against DDoS attacks, SQL injection, XSS, and other web exploits.

## Features

- **DDoS Protection**: Rate limiting to prevent volumetric attacks
- **AWS Managed Rule Groups**: Pre-built protection against common threats
  - Core Rule Set (OWASP Top 10)
  - SQL Injection prevention
  - Known Bad Inputs protection
  - IP Reputation blocking
  - Bot Control (optional, premium)
  - Account Takeover Prevention (optional, premium)
- **Geographic Blocking**: Restrict access by country
- **IP Allow/Block Lists**: Explicit IP-based access control
- **Custom Rules**: Flexible rule creation for specific needs
- **CloudWatch Logging**: Full request logging and metrics
- **Multi-Scope Support**: REGIONAL (ALB/API Gateway) or CLOUDFRONT
- **Auto-Association**: Automatic ALB association

## Usage

### Example 1: Basic WAF with Core Protection

```hcl
module "waf" {
  source = "../../modules/security/waf-web-acl"

  # Customer Context
  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "pro"
  environment       = "production"
  region            = "us-east-1"

  # WAF Configuration
  scope          = "REGIONAL"  # For ALB/API Gateway
  default_action = "allow"     # Allow by default, block specific threats

  # Rate Limiting (DDoS Protection)
  rate_limit_enabled  = true
  rate_limit_requests = 2000   # 2000 requests per 5 minutes per IP
  rate_limit_action   = "block"

  # AWS Managed Rules (recommended defaults)
  enable_aws_managed_rules_core              = true  # OWASP Top 10
  enable_aws_managed_rules_known_bad_inputs  = true  # Known attack patterns
  enable_aws_managed_rules_sqli              = true  # SQL Injection
  enable_aws_managed_rules_ip_reputation     = true  # Known malicious IPs

  # Logging
  enable_logging                = true
  log_destination_type          = "cloudwatch"
  cloudwatch_log_retention_days = 30

  tags = {
    Application = "web-application"
    CostCenter  = "security"
  }
}

# Use WAF with ALB
module "alb" {
  source = "../../modules/compute/alb"
  
  web_acl_arn = module.waf.web_acl_arn
  
  # ... other ALB configuration ...
}
```

### Example 2: Enterprise WAF with All Protection Layers

```hcl
module "enterprise_waf" {
  source = "../../modules/security/waf-web-acl"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "enterprise"
  environment       = "production"
  region            = "us-east-1"

  scope          = "REGIONAL"
  default_action = "allow"

  # Aggressive Rate Limiting
  rate_limit_enabled  = true
  rate_limit_requests = 1000   # More restrictive for enterprise
  rate_limit_action   = "block"

  # All AWS Managed Rules
  enable_aws_managed_rules_core              = true
  enable_aws_managed_rules_known_bad_inputs  = true
  enable_aws_managed_rules_sqli              = true
  enable_aws_managed_rules_linux             = true  # Linux OS protection
  enable_aws_managed_rules_anonymous_ip      = true  # Block VPNs/proxies
  enable_aws_managed_rules_ip_reputation     = true
  enable_aws_managed_rules_bot_control       = true  # Premium: $10/month + $1/million requests

  # Geographic Blocking
  geo_blocking_enabled   = true
  geo_blocking_countries = ["CN", "RU", "KP", "IR"]  # Block specific countries
  geo_blocking_action    = "block"

  # IP Allow List (office/partner IPs bypass all rules)
  ip_allow_list = [
    "203.0.113.0/24",    # Office network
    "198.51.100.5/32"    # Partner API server
  ]

  # IP Block List (known attackers)
  ip_block_list = [
    "192.0.2.100/32",    # Known malicious IP
    "192.0.2.0/24"       # Malicious network
  ]

  # Logging to CloudWatch with long retention
  enable_logging                = true
  log_destination_type          = "cloudwatch"
  cloudwatch_log_retention_days = 90

  # Monitoring
  enable_cloudwatch_metrics = true
  enable_sampled_requests   = true

  tags = {
    Application = "critical-app"
    Compliance  = "pci-dss"
  }
}
```

### Example 3: CloudFront WAF (Global)

```hcl
# CloudFront WAF MUST be in us-east-1
module "cloudfront_waf" {
  source = "../../modules/security/waf-web-acl"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "pro"
  environment       = "production"
  region            = "us-east-1"  # REQUIRED for CloudFront

  scope          = "CLOUDFRONT"  # Global scope
  default_action = "allow"

  # Rate Limiting
  rate_limit_enabled  = true
  rate_limit_requests = 5000  # Higher for global CDN
  rate_limit_action   = "block"

  # Core protection
  enable_aws_managed_rules_core              = true
  enable_aws_managed_rules_known_bad_inputs  = true
  enable_aws_managed_rules_sqli              = true

  # Logging
  enable_logging                = true
  log_destination_type          = "cloudwatch"
  cloudwatch_log_retention_days = 30

  tags = {
    Service = "cloudfront"
    Global  = "true"
  }
}

# CloudFront distribution using WAF
resource "aws_cloudfront_distribution" "cdn" {
  # ... other configuration ...

  web_acl_id = module.cloudfront_waf.web_acl_arn

  # CloudFront requires us-east-1 WAF
}
```

### Example 4: Custom Rules for API Protection

```hcl
module "api_waf" {
  source = "../../modules/security/waf-web-acl"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "pro"
  environment       = "production"
  region            = "us-east-1"

  scope          = "REGIONAL"
  default_action = "allow"

  # Rate Limiting
  rate_limit_enabled  = true
  rate_limit_requests = 2000
  rate_limit_action   = "block"

  # AWS Managed Rules
  enable_aws_managed_rules_core = true
  enable_aws_managed_rules_sqli = true

  # Custom Rules
  custom_rules = [
    # Block bad user agents
    {
      name     = "BlockBadBots"
      priority = 100
      action   = "block"
      statement = {
        byte_match_statement = {
          search_string         = "BadBot"
          field_to_match        = { single_header = { name = "user-agent" } }
          positional_constraint = "CONTAINS"
          text_transformations  = [{ priority = 0, type = "LOWERCASE" }]
        }
      }
    },
    
    # Require API key header
    {
      name     = "RequireAPIKey"
      priority = 101
      action   = "block"
      statement = {
        byte_match_statement = {
          search_string         = "x-api-key"
          field_to_match        = { single_header = { name = "x-api-key" } }
          positional_constraint = "EXACTLY"
          text_transformations  = [{ priority = 0, type = "NONE" }]
        }
      }
    }
  ]

  enable_logging                = true
  log_destination_type          = "cloudwatch"
  cloudwatch_log_retention_days = 30
}
```

### Example 5: Multi-Region WAF with ALB Auto-Association

```hcl
# US East WAF
module "waf_us_east" {
  source = "../../modules/security/waf-web-acl"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "enterprise"
  environment       = "production"
  region            = "us-east-1"

  scope          = "REGIONAL"
  default_action = "allow"

  rate_limit_enabled  = true
  rate_limit_requests = 2000
  rate_limit_action   = "block"

  enable_aws_managed_rules_core             = true
  enable_aws_managed_rules_sqli             = true
  enable_aws_managed_rules_ip_reputation    = true

  # Auto-associate with ALB
  associate_alb = true
  alb_arn       = module.alb_us_east.alb_arn

  enable_logging                = true
  log_destination_type          = "cloudwatch"
  cloudwatch_log_retention_days = 30
}

# EU West WAF
module "waf_eu_west" {
  source = "../../modules/security/waf-web-acl"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "enterprise"
  environment       = "production"
  region            = "eu-west-1"

  scope          = "REGIONAL"
  default_action = "allow"

  rate_limit_enabled  = true
  rate_limit_requests = 2000
  rate_limit_action   = "block"

  enable_aws_managed_rules_core             = true
  enable_aws_managed_rules_sqli             = true
  enable_aws_managed_rules_ip_reputation    = true

  # Auto-associate with ALB
  associate_alb = true
  alb_arn       = module.alb_eu_west.alb_arn

  enable_logging                = true
  log_destination_type          = "cloudwatch"
  cloudwatch_log_retention_days = 30
}

# APAC WAF
module "waf_ap_southeast" {
  source = "../../modules/security/waf-web-acl"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "enterprise"
  environment       = "production"
  region            = "ap-southeast-1"

  scope          = "REGIONAL"
  default_action = "allow"

  rate_limit_enabled  = true
  rate_limit_requests = 2000
  rate_limit_action   = "block"

  enable_aws_managed_rules_core             = true
  enable_aws_managed_rules_sqli             = true
  enable_aws_managed_rules_ip_reputation    = true

  # Auto-associate with ALB
  associate_alb = true
  alb_arn       = module.alb_ap_southeast.alb_arn

  enable_logging                = true
  log_destination_type          = "cloudwatch"
  cloudwatch_log_retention_days = 30
}
```

### Example 6: WordPress-Specific Protection

```hcl
module "wordpress_waf" {
  source = "../../modules/security/waf-web-acl"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "pro"
  environment       = "production"
  region            = "us-east-1"

  scope          = "REGIONAL"
  default_action = "allow"

  # Rate Limiting
  rate_limit_enabled  = true
  rate_limit_requests = 2000
  rate_limit_action   = "block"

  # WordPress-specific protection
  enable_aws_managed_rules_core       = true
  enable_aws_managed_rules_sqli       = true
  enable_aws_managed_rules_php        = true        # PHP protection
  enable_aws_managed_rules_wordpress  = true        # WordPress-specific rules

  # Block common WordPress attack sources
  geo_blocking_enabled   = true
  geo_blocking_countries = ["CN", "RU"]
  geo_blocking_action    = "block"

  enable_logging                = true
  log_destination_type          = "cloudwatch"
  cloudwatch_log_retention_days = 30

  tags = {
    Application = "wordpress"
    CMS         = "true"
  }
}
```

### Example 7: CAPTCHA-Based Rate Limiting

```hcl
module "captcha_waf" {
  source = "../../modules/security/waf-web-acl"

  customer_id       = "acme-corp"
  customer_name     = "ACME Corporation"
  architecture_type = "forge"
  plan_tier         = "pro"
  environment       = "production"
  region            = "us-east-1"

  scope          = "REGIONAL"
  default_action = "allow"

  # CAPTCHA instead of blocking
  rate_limit_enabled  = true
  rate_limit_requests = 2000
  rate_limit_action   = "captcha"  # Present CAPTCHA challenge instead of blocking

  enable_aws_managed_rules_core             = true
  enable_aws_managed_rules_ip_reputation    = true

  enable_logging                = true
  log_destination_type          = "cloudwatch"
  cloudwatch_log_retention_days = 30

  tags = {
    RateLimitMode = "captcha"
  }
}
```

## AWS Managed Rule Groups

### Core Protection (Recommended for All)

| Rule Group | Cost | Description | Recommended |
|------------|------|-------------|-------------|
| **Core Rule Set** | Free | OWASP Top 10, common vulnerabilities | ✅ Yes |
| **Known Bad Inputs** | Free | Known malicious patterns (log4j, etc.) | ✅ Yes |
| **SQL Injection** | Free | SQL injection prevention | ✅ Yes |
| **IP Reputation** | Free | Known malicious IP addresses | ✅ Yes |

### Application-Specific Protection

| Rule Group | Cost | Description | Use When |
|------------|------|-------------|----------|
| **Linux OS** | Free | Linux-specific exploits | Linux backend |
| **Windows OS** | Free | Windows-specific exploits | Windows backend |
| **PHP** | Free | PHP application protection | PHP app |
| **WordPress** | Free | WordPress-specific attacks | WordPress site |

### Advanced Protection (Premium)

| Rule Group | Cost | Description | Use When |
|------------|------|-------------|----------|
| **Anonymous IP** | Free | Blocks VPNs, proxies, Tor | High security requirements |
| **Bot Control** | **$10/month + $1/million requests** | Sophisticated bot detection | E-commerce, high-value targets |
| **Account Takeover Prevention (ATP)** | **$10/month + $1/million requests** | Login protection, credential stuffing | User authentication flows |

## Rate Limiting Configuration

### Recommended Thresholds

| Traffic Type | Requests per 5 min | Use Case |
|--------------|-------------------|----------|
| **100-500** | Very restrictive | Internal APIs, admin panels |
| **1000-2000** | Standard | Public APIs, web applications |
| **5000-10000** | Permissive | CDN, high-traffic sites |
| **20000+** | Very permissive | Global CDN, public content |

### Rate Limit Actions

- **block**: Immediately block requests (best for DDoS)
- **count**: Monitor only (testing/tuning)
- **captcha**: Present CAPTCHA challenge (user-friendly)

## Geographic Blocking

### Common Country Codes

| Region | Countries | Codes |
|--------|-----------|-------|
| **High-risk** | China, Russia, North Korea | `CN`, `RU`, `KP` |
| **OFAC Sanctions** | Iran, Syria, Cuba | `IR`, `SY`, `CU` |
| **Europe (GDPR)** | EU member states | `DE`, `FR`, `GB`, `IT`, etc. |
| **North America** | US, Canada, Mexico | `US`, `CA`, `MX` |

Full list: [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)

## Integration Examples

### With ALB Module

```hcl
module "waf" {
  source = "../../modules/security/waf-web-acl"
  
  # ... WAF configuration ...
}

module "alb" {
  source = "../../modules/compute/alb"
  
  web_acl_arn = module.waf.web_acl_arn
  
  # ... ALB configuration ...
}
```

### With API Gateway

```hcl
module "waf" {
  source = "../../modules/security/waf-web-acl"
  
  scope = "REGIONAL"
  # ... configuration ...
}

resource "aws_api_gateway_stage" "prod" {
  # ... configuration ...
  
  web_acl_arn = module.waf.web_acl_arn
}
```

### With CloudFront

```hcl
# WAF MUST be in us-east-1 for CloudFront
module "waf" {
  source = "../../modules/security/waf-web-acl"
  
  region = "us-east-1"
  scope  = "CLOUDFRONT"
  # ... configuration ...
}

resource "aws_cloudfront_distribution" "cdn" {
  # ... configuration ...
  
  web_acl_id = module.waf.web_acl_arn
}
```

## Logging and Monitoring

### CloudWatch Logs

```hcl
module "waf" {
  source = "../../modules/security/waf-web-acl"
  
  enable_logging                = true
  log_destination_type          = "cloudwatch"
  cloudwatch_log_retention_days = 30  # 1, 3, 7, 14, 30, 60, 90, etc.
  
  # ... other configuration ...
}
```

**Log Format**: JSON with request details, matched rules, action taken

### CloudWatch Metrics

Available metrics:
- `AllowedRequests`: Requests allowed by WAF
- `BlockedRequests`: Requests blocked by WAF
- `CountedRequests`: Requests matched by count rules
- `PassedRequests`: Requests passed through (no rule match)

### Querying Logs

```bash
# Get blocked requests
aws logs filter-log-events \
  --log-group-name /aws/wafv2/forge-production-waf \
  --filter-pattern '{ $.action = "BLOCK" }' \
  --start-time $(date -u -d '1 hour ago' +%s)000

# Get rate limit violations
aws logs filter-log-events \
  --log-group-name /aws/wafv2/forge-production-waf \
  --filter-pattern '{ $.ruleGroupList[*].ruleMatchDetails[*].ruleId = "RateLimitRule" }'
```

## Troubleshooting

### False Positives (Legitimate Traffic Blocked)

**Symptom**: Users reporting 403 errors

**Solutions**:
1. Check CloudWatch Logs for blocked requests
2. Identify the rule causing blocks
3. Add users to IP allow list if trusted
4. Exclude specific rules from managed rule groups
5. Use `count` action instead of `block` for testing

```hcl
# Example: Exclude specific rule
locals {
  managed_rule_groups = {
    core_rule_set = {
      enabled  = true
      name     = "AWSManagedRulesCommonRuleSet"
      vendor   = "AWS"
      priority = 20
      excluded_rules = ["SizeRestrictions_BODY"]  # Exclude body size check
    }
  }
}
```

### Rate Limit Too Aggressive

**Symptom**: Legitimate users hitting rate limits

**Solutions**:
1. Increase `rate_limit_requests` threshold
2. Change `rate_limit_action` to `captcha`
3. Add office/partner IPs to allow list
4. Use different thresholds per endpoint (custom rules)

### WAF Not Blocking Attacks

**Symptom**: Attacks getting through

**Solutions**:
1. Enable more AWS managed rule groups
2. Lower rate limit threshold
3. Enable geographic blocking
4. Add attacker IPs to block list
5. Review CloudWatch metrics for rule effectiveness

### High Costs

**Symptom**: Unexpected WAF charges

**Cost Breakdown**:
- Web ACL: $5/month
- Rules: $1/month per rule (first 10 free)
- Requests: $0.60 per million
- Bot Control: **$10/month + $1/million requests**
- ATP: **$10/month + $1/million requests**
- Logs: $0.50/GB ingested, $0.03/GB stored

**Solutions**:
1. Disable premium rule groups (Bot Control, ATP) if not needed
2. Reduce CloudWatch log retention
3. Use count action for testing (no blocks = fewer logs)
4. Consolidate rules where possible

## Security Best Practices

1. **Enable Core Protection**: Always enable Core Rule Set, SQLi, Known Bad Inputs
2. **Use Rate Limiting**: Protect against DDoS (2000 req/5min is good default)
3. **Monitor Logs**: Review CloudWatch Logs regularly for attack patterns
4. **IP Allow List**: Add trusted IPs (office, partners) to bypass rules
5. **Test Before Blocking**: Use `count` action to test new rules
6. **Regional Deployment**: Deploy WAF in each region with ALBs
7. **CloudFront Requires us-east-1**: Global WAF must be in us-east-1
8. **Update Managed Rules**: AWS updates automatically, no action needed
9. **Least Privilege**: Default action `allow`, explicit blocks
10. **Log Retention**: 30-90 days for security analysis

## Cost Optimization

### Basic Setup (Minimal Cost)

```hcl
# Cost: ~$6-8/month + $0.60 per million requests
module "waf_basic" {
  source = "../../modules/security/waf-web-acl"
  
  # Core protection only
  enable_aws_managed_rules_core              = true
  enable_aws_managed_rules_known_bad_inputs  = true
  enable_aws_managed_rules_sqli              = true
  
  rate_limit_enabled = true
  
  # No premium features
  enable_aws_managed_rules_bot_control       = false
  enable_aws_managed_rules_account_takeover  = false
  
  # Short log retention
  cloudwatch_log_retention_days = 7
}
```

### Enterprise Setup (Full Protection)

```hcl
# Cost: ~$30-40/month + $2-3 per million requests
module "waf_enterprise" {
  source = "../../modules/security/waf-web-acl"
  
  # All managed rules
  enable_aws_managed_rules_core              = true
  enable_aws_managed_rules_sqli              = true
  enable_aws_managed_rules_ip_reputation     = true
  enable_aws_managed_rules_bot_control       = true  # +$10/month
  enable_aws_managed_rules_account_takeover  = true  # +$10/month
  
  # Geographic blocking, IP lists, custom rules
  geo_blocking_enabled = true
  
  # Long log retention for compliance
  cloudwatch_log_retention_days = 90
}
```

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
| region | AWS region for the WAF Web ACL | `string` | n/a | yes |
| architecture_type | Type of architecture | `string` | `"forge"` | no |
| plan_tier | Service plan tier | `string` | `"basic"` | no |
| name | WAF Web ACL name | `string` | `null` | no |
| scope | Scope (REGIONAL or CLOUDFRONT) | `string` | `"REGIONAL"` | no |
| default_action | Default action (allow or block) | `string` | `"allow"` | no |
| rate_limit_enabled | Enable rate limiting | `bool` | `true` | no |
| rate_limit_requests | Rate limit threshold | `number` | `2000` | no |
| rate_limit_action | Rate limit action (block, count, captcha) | `string` | `"block"` | no |
| enable_aws_managed_rules_* | Enable specific managed rule groups | `bool` | varies | no |
| geo_blocking_enabled | Enable geographic blocking | `bool` | `false` | no |
| geo_blocking_countries | Countries to block | `list(string)` | `[]` | no |
| ip_allow_list | IP addresses to allow | `list(string)` | `[]` | no |
| ip_block_list | IP addresses to block | `list(string)` | `[]` | no |
| custom_rules | Custom WAF rules | `list(object)` | `[]` | no |
| enable_logging | Enable WAF logging | `bool` | `true` | no |
| log_destination_type | Log destination type | `string` | `"cloudwatch"` | no |
| cloudwatch_log_retention_days | Log retention days | `number` | `30` | no |
| associate_alb | Auto-associate with ALB | `bool` | `false` | no |
| alb_arn | ALB ARN for association | `string` | `null` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| web_acl_arn | ARN of the WAF Web ACL |
| web_acl_id | ID of the WAF Web ACL |
| web_acl_name | Name of the WAF Web ACL |
| web_acl_capacity | WCU capacity used |
| ip_allow_list_arn | ARN of IP allow list |
| ip_block_list_arn | ARN of IP block list |
| cloudwatch_log_group_name | CloudWatch Log Group name |
| alb_integration | ALB integration config |
| cloudfront_integration | CloudFront integration config |
| waf_summary | Complete WAF summary |

## Authors

MOAI Engineering Team

## License

Proprietary - MOAI Platform
