# Application Load Balancer (ALB) Module

Terraform module for creating and managing AWS Application Load Balancers in the Forge platform. This module provides HTTP/HTTPS load balancing with advanced routing, target group management, health checks, and seamless integration with Route 53 geolocation routing.

## Features

- **Load Balancing**: HTTP/HTTPS traffic distribution across multiple targets
- **Multi-AZ**: High availability across multiple availability zones
- **Target Groups**: Flexible target group configuration (instance, IP, Lambda, ALB)
- **Health Checks**: Configurable health check parameters per target group
- **Listeners**: HTTP (port 80) and HTTPS (port 443) with SSL/TLS
- **Security**: TLS 1.3 support, WAF integration, header validation
- **Session Affinity**: Cookie-based stickiness for stateful applications
- **Access Logging**: S3-based access logs for compliance and debugging
- **Route 53 Integration**: Seamless alias record support for geolocation routing
- **Customer-Aware**: Support for shared and dedicated architectures

## Usage

### Example 1: Basic Internet-Facing ALB with HTTP to HTTPS Redirect

```hcl
module "public_alb" {
  source = "../../modules/compute/alb"

  # Customer context
  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = "production"
  region            = "us-east-1"

  # ALB configuration
  internal        = false
  ip_address_type = "ipv4"

  # Network configuration
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.subnet.public_subnet_ids
  security_group_ids = [module.alb_security_group.security_group_id]

  # Target groups
  target_groups = {
    web = {
      port     = 80
      protocol = "HTTP"
      target_type = "instance"
      
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200"
      }
    }
  }

  # HTTP listener (redirect to HTTPS)
  http_listener = {
    enabled        = true
    port           = 80
    redirect_https = true
  }

  # HTTPS listener
  https_listener = {
    enabled          = true
    port             = 443
    certificate_arn  = module.acm_certificate.certificate_arn
    ssl_policy       = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    target_group_key = "web"
  }

  # Access logging
  enable_access_logs  = true
  access_logs_bucket  = module.logs_bucket.bucket_name
  access_logs_prefix  = "alb/production"

  # Security
  enable_deletion_protection = true
  drop_invalid_header_fields = true

  tags = {
    Purpose = "production-web-alb"
  }
}
```

### Example 2: Multi-Region ALB for Geolocation Routing

**Use Case**: Deploy ALBs in multiple regions and use Route 53 geolocation routing to direct users to the nearest region.

```hcl
# ========================================
# US East (Virginia) ALB
# ========================================

module "alb_us_east" {
  source = "../../modules/compute/alb"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = "production"
  region            = "us-east-1"

  vpc_id             = module.vpc_us_east.vpc_id
  subnet_ids         = module.subnet_us_east.public_subnet_ids
  security_group_ids = [module.alb_sg_us_east.security_group_id]

  target_groups = {
    api = {
      port     = 8080
      protocol = "HTTP"
      
      health_check = {
        path    = "/api/health"
        matcher = "200"
      }
    }
  }

  https_listener = {
    enabled          = true
    certificate_arn  = module.acm_us_east.certificate_arn
    target_group_key = "api"
  }

  enable_access_logs = true
  access_logs_bucket = module.logs_bucket.bucket_name
  access_logs_prefix = "alb/us-east-1"

  tags = {
    Region = "us-east-1"
    Purpose = "api-geolocation"
  }
}

# ========================================
# EU West (Ireland) ALB
# ========================================

module "alb_eu_west" {
  source = "../../modules/compute/alb"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = "production"
  region            = "eu-west-1"

  vpc_id             = module.vpc_eu_west.vpc_id
  subnet_ids         = module.subnet_eu_west.public_subnet_ids
  security_group_ids = [module.alb_sg_eu_west.security_group_id]

  target_groups = {
    api = {
      port     = 8080
      protocol = "HTTP"
      
      health_check = {
        path    = "/api/health"
        matcher = "200"
      }
    }
  }

  https_listener = {
    enabled          = true
    certificate_arn  = module.acm_eu_west.certificate_arn
    target_group_key = "api"
  }

  enable_access_logs = true
  access_logs_bucket = module.logs_bucket.bucket_name
  access_logs_prefix = "alb/eu-west-1"

  tags = {
    Region = "eu-west-1"
    Purpose = "api-geolocation"
  }
}

# ========================================
# Asia Pacific (Singapore) ALB
# ========================================

module "alb_ap_southeast" {
  source = "../../modules/compute/alb"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = "production"
  region            = "ap-southeast-1"

  vpc_id             = module.vpc_ap_southeast.vpc_id
  subnet_ids         = module.subnet_ap_southeast.public_subnet_ids
  security_group_ids = [module.alb_sg_ap_southeast.security_group_id]

  target_groups = {
    api = {
      port     = 8080
      protocol = "HTTP"
      
      health_check = {
        path    = "/api/health"
        matcher = "200"
      }
    }
  }

  https_listener = {
    enabled          = true
    certificate_arn  = module.acm_ap_southeast.certificate_arn
    target_group_key = "api"
  }

  enable_access_logs = true
  access_logs_bucket = module.logs_bucket.bucket_name
  access_logs_prefix = "alb/ap-southeast-1"

  tags = {
    Region = "ap-southeast-1"
    Purpose = "api-geolocation"
  }
}

# ========================================
# Route 53 Geolocation Routing
# ========================================

# North America users → US ALB
module "route53_north_america" {
  source = "../../modules/network/route53-record"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = "production"
  region            = "us-east-1"

  zone_id = module.hosted_zone.zone_id
  name    = "api.example.com"
  type    = "A"

  # Alias to US ALB
  alias = {
    name                   = module.alb_us_east.dns_name
    zone_id                = module.alb_us_east.zone_id
    evaluate_target_health = true
  }

  # Geolocation: North America
  routing_policy = "geolocation"
  set_identifier = "api-north-america"
  
  geolocation = {
    continent = "NA"
  }

  tags = {
    Region = "north-america"
  }
}

# Europe users → EU ALB
module "route53_europe" {
  source = "../../modules/network/route53-record"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = "production"
  region            = "eu-west-1"

  zone_id = module.hosted_zone.zone_id
  name    = "api.example.com"
  type    = "A"

  # Alias to EU ALB
  alias = {
    name                   = module.alb_eu_west.dns_name
    zone_id                = module.alb_eu_west.zone_id
    evaluate_target_health = true
  }

  # Geolocation: Europe
  routing_policy = "geolocation"
  set_identifier = "api-europe"
  
  geolocation = {
    continent = "EU"
  }

  tags = {
    Region = "europe"
  }
}

# Asia Pacific users → APAC ALB
module "route53_asia_pacific" {
  source = "../../modules/network/route53-record"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = "production"
  region            = "ap-southeast-1"

  zone_id = module.hosted_zone.zone_id
  name    = "api.example.com"
  type    = "A"

  # Alias to APAC ALB
  alias = {
    name                   = module.alb_ap_southeast.dns_name
    zone_id                = module.alb_ap_southeast.zone_id
    evaluate_target_health = true
  }

  # Geolocation: Asia Pacific
  routing_policy = "geolocation"
  set_identifier = "api-asia-pacific"
  
  geolocation = {
    continent = "AS"
  }

  tags = {
    Region = "asia-pacific"
  }
}

# Default fallback → US ALB
module "route53_default" {
  source = "../../modules/network/route53-record"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = "production"
  region            = "us-east-1"

  zone_id = module.hosted_zone.zone_id
  name    = "api.example.com"
  type    = "A"

  # Alias to US ALB (default)
  alias = {
    name                   = module.alb_us_east.dns_name
    zone_id                = module.alb_us_east.zone_id
    evaluate_target_health = true
  }

  # Geolocation: Default
  routing_policy = "geolocation"
  set_identifier = "api-default"
  
  geolocation = {}

  tags = {
    Region = "default"
  }
}
```

### Example 3: Internal ALB for Microservices

```hcl
module "internal_alb" {
  source = "../../modules/compute/alb"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = "production"
  region            = var.region

  # Internal ALB (not internet-facing)
  internal        = true
  ip_address_type = "ipv4"

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.subnet.private_subnet_ids
  security_group_ids = [module.internal_alb_sg.security_group_id]

  # Multiple target groups for microservices
  target_groups = {
    auth_service = {
      port     = 8081
      protocol = "HTTP"
      
      health_check = {
        path = "/auth/health"
      }
    }

    user_service = {
      port     = 8082
      protocol = "HTTP"
      
      health_check = {
        path = "/users/health"
      }
    }

    order_service = {
      port     = 8083
      protocol = "HTTP"
      
      health_check = {
        path = "/orders/health"
      }
    }
  }

  # HTTP listener (internal services don't need HTTPS)
  http_listener = {
    enabled          = true
    port             = 80
    redirect_https   = false
    target_group_key = "auth_service"
  }

  enable_access_logs = true
  access_logs_bucket = module.logs_bucket.bucket_name
  access_logs_prefix = "alb/internal"

  # Lower security requirements for internal ALB
  enable_deletion_protection = false

  tags = {
    Purpose = "internal-microservices"
  }
}
```

### Example 4: ALB with Session Stickiness

```hcl
module "stateful_alb" {
  source = "../../modules/compute/alb"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = "production"
  region            = var.region

  internal        = false
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.subnet.public_subnet_ids
  security_group_ids = [module.alb_sg.security_group_id]

  target_groups = {
    app = {
      port     = 8080
      protocol = "HTTP"
      
      health_check = {
        path = "/health"
      }

      # Enable session stickiness
      stickiness = {
        enabled         = true
        type            = "lb_cookie"
        cookie_duration = 3600  # 1 hour
      }
    }
  }

  https_listener = {
    enabled          = true
    certificate_arn  = module.acm_certificate.certificate_arn
    target_group_key = "app"
  }

  tags = {
    Purpose = "stateful-application"
  }
}
```

### Example 5: ALB with WAF Integration

```hcl
# WAF Web ACL
resource "aws_wafv2_web_acl" "main" {
  name  = "forge-production-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimitRule"
    priority = 1

    override_action {
      none {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "forge-production-waf"
    sampled_requests_enabled   = true
  }
}

# ALB with WAF
module "protected_alb" {
  source = "../../modules/compute/alb"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = "production"
  region            = var.region

  internal           = false
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.subnet.public_subnet_ids
  security_group_ids = [module.alb_sg.security_group_id]

  target_groups = {
    api = {
      port     = 8080
      protocol = "HTTP"
      health_check = {
        path = "/api/health"
      }
    }
  }

  https_listener = {
    enabled          = true
    certificate_arn  = module.acm_certificate.certificate_arn
    target_group_key = "api"
  }

  # Associate WAF Web ACL
  web_acl_arn = aws_wafv2_web_acl.main.arn

  tags = {
    Purpose = "waf-protected-api"
  }
}
```

### Example 6: ALB with Multiple Target Groups (Blue-Green Deployment)

```hcl
module "blue_green_alb" {
  source = "../../modules/compute/alb"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = "production"
  region            = var.region

  internal           = false
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.subnet.public_subnet_ids
  security_group_ids = [module.alb_sg.security_group_id]

  # Blue and Green target groups
  target_groups = {
    blue = {
      port     = 8080
      protocol = "HTTP"
      
      health_check = {
        path = "/health"
      }
    }

    green = {
      port     = 8081
      protocol = "HTTP"
      
      health_check = {
        path = "/health"
      }
    }
  }

  https_listener = {
    enabled          = true
    certificate_arn  = module.acm_certificate.certificate_arn
    target_group_key = "blue"  # Initially point to blue
  }

  tags = {
    Purpose     = "blue-green-deployment"
    Deployment  = "blue"
  }
}

# Switch to green by updating target_group_key to "green"
# Then gradually deregister blue targets
```

### Example 7: ALB with IP Target Type (for Containers)

```hcl
module "ecs_alb" {
  source = "../../modules/compute/alb"

  customer_id       = var.customer_id
  customer_name     = var.customer_name
  architecture_type = var.architecture_type
  plan_tier         = var.plan_tier
  environment       = "production"
  region            = var.region

  internal           = false
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.subnet.public_subnet_ids
  security_group_ids = [module.alb_sg.security_group_id]

  target_groups = {
    ecs_service = {
      port        = 8080
      protocol    = "HTTP"
      target_type = "ip"  # For ECS Fargate or IP-based targets
      
      health_check = {
        path                = "/health"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200"
      }

      # Slow start for gradual traffic increase
      slow_start                    = 30
      deregistration_delay          = 30
      load_balancing_algorithm_type = "least_outstanding_requests"
    }
  }

  https_listener = {
    enabled          = true
    certificate_arn  = module.acm_certificate.certificate_arn
    target_group_key = "ecs_service"
  }

  tags = {
    Purpose = "ecs-fargate"
  }
}
```

## Target Group Configuration

### Target Types

- **instance**: EC2 instances (default)
- **ip**: IP addresses (ECS Fargate, on-premises servers)
- **lambda**: Lambda functions
- **alb**: Another ALB (chaining)

### Health Check Parameters

| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| **enabled** | Enable health checks | `true` | - |
| **interval** | Time between health checks (seconds) | `30` | 5-300 |
| **path** | Health check path | `/health` | - |
| **port** | Health check port | `traffic-port` | 1-65535 or `traffic-port` |
| **protocol** | Health check protocol | `HTTP` | HTTP, HTTPS, TCP |
| **timeout** | Health check timeout (seconds) | `5` | 2-120 |
| **healthy_threshold** | Consecutive successes to mark healthy | `2` | 2-10 |
| **unhealthy_threshold** | Consecutive failures to mark unhealthy | `2` | 2-10 |
| **matcher** | HTTP codes for successful health check | `200-299` | 200-499 |

### Load Balancing Algorithms

- **round_robin**: Distribute requests evenly (default)
- **least_outstanding_requests**: Route to target with fewest active requests
- **weighted_random**: Random distribution with weights

### Stickiness Configuration

```hcl
stickiness = {
  enabled         = true
  type            = "lb_cookie"       # or "app_cookie"
  cookie_duration = 86400             # 24 hours (in seconds)
  cookie_name     = "AWSALB-STICKY"   # Only for app_cookie type
}
```

## SSL/TLS Configuration

### Recommended SSL Policies (TLS 1.3)

- **ELBSecurityPolicy-TLS13-1-2-2021-06** (Recommended) - TLS 1.3 + TLS 1.2
- **ELBSecurityPolicy-TLS13-1-2-Res-2021-06** - Restricted TLS 1.3 + TLS 1.2
- **ELBSecurityPolicy-TLS13-1-2-Ext1-2021-06** - Extended TLS 1.3 + TLS 1.2
- **ELBSecurityPolicy-TLS13-1-2-Ext2-2021-06** - Extended with additional ciphers

### Legacy SSL Policies (TLS 1.2 only)

- **ELBSecurityPolicy-2016-08** - General use
- **ELBSecurityPolicy-FS-2018-06** - Forward secrecy

### ALPN Policy (Application-Layer Protocol Negotiation)

```hcl
alpn_policy = "HTTP2Preferred"  # HTTP/2, then HTTP/1.1
alpn_policy = "HTTP2Only"       # HTTP/2 only
alpn_policy = "None"            # No ALPN
```

## Security Best Practices

### 1. Enable Deletion Protection (Production)

```hcl
enable_deletion_protection = true
```

### 2. Drop Invalid HTTP Headers

```hcl
drop_invalid_header_fields = true
```

### 3. Use Strictest Desync Mitigation

```hcl
desync_mitigation_mode = "strictest"  # or "defensive"
```

### 4. Preserve Host Header

```hcl
preserve_host_header = true
```

### 5. Use WAF for DDoS Protection

```hcl
web_acl_arn = aws_wafv2_web_acl.main.arn
```

### 6. Enable Access Logging

```hcl
enable_access_logs  = true
access_logs_bucket  = module.logs_bucket.bucket_name
access_logs_prefix  = "alb/production"
```

## Access Logs

Access logs contain:
- Request time
- Client IP address
- Request path and query string
- HTTP status code
- Response size
- User-Agent
- SSL cipher and protocol
- Target processing time

### Log Format

```
http 2025-11-23T10:30:45.123456Z app/forge-production-alb/abc123 
192.0.2.1:12345 10.0.1.50:8080 0.001 0.002 0.000 200 200 
123 456 "GET https://api.example.com:443/users/123 HTTP/1.1" 
"Mozilla/5.0" ECDHE-RSA-AES128-GCM-SHA256 TLSv1.2
```

## Integration with Other Modules

### VPC and Subnets

```hcl
module "vpc" {
  source = "../../modules/network/vpc"
  # ... VPC configuration ...
}

module "subnet" {
  source = "../../modules/network/subnet"
  # ... Subnet configuration ...
}

module "alb" {
  source = "../../modules/compute/alb"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.subnet.public_subnet_ids
  # ...
}
```

### Security Groups

```hcl
module "alb_security_group" {
  source = "../../modules/network/security-group"
  
  # Allow HTTP/HTTPS from internet
  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  # ...
}

module "alb" {
  source = "../../modules/compute/alb"
  
  security_group_ids = [module.alb_security_group.security_group_id]
  # ...
}
```

### Route 53 Alias Records

```hcl
module "alb" {
  source = "../../modules/compute/alb"
  # ... ALB configuration ...
}

module "route53_record" {
  source = "../../modules/network/route53-record"
  
  zone_id = module.hosted_zone.zone_id
  name    = "app.example.com"
  type    = "A"
  
  # Alias to ALB (free DNS queries)
  alias = {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}
```

## Troubleshooting

### ALB Not Accessible

```bash
# Check ALB state
aws elbv2 describe-load-balancers --names forge-production-alb

# Check target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Check security group rules
aws ec2 describe-security-groups --group-ids <sg-id>
```

### Targets Unhealthy

**Common causes**:
1. **Security group**: Target security group doesn't allow traffic from ALB
2. **Health check path**: Incorrect health check endpoint
3. **Port mismatch**: Health check port doesn't match application port
4. **Timeout too short**: Application takes longer than timeout to respond

```bash
# Check target health details
aws elbv2 describe-target-health \
  --target-group-arn <arn> \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Reason]'

# Test health check from ALB subnet
curl -I http://<target-ip>:<port>/health
```

### 502 Bad Gateway

**Causes**:
- Target returned invalid HTTP response
- Target closed connection before sending response
- Target took longer than `idle_timeout` (default 60s)

**Solutions**:
1. Check target application logs
2. Increase `idle_timeout` if needed
3. Verify target is sending valid HTTP responses

### 503 Service Unavailable

**Causes**:
- No healthy targets in target group
- All targets are deregistering

**Solutions**:
1. Fix target health issues
2. Ensure at least one healthy target

### 504 Gateway Timeout

**Causes**:
- Target didn't respond within timeout period (60 seconds)

**Solutions**:
1. Increase `idle_timeout`
2. Optimize application response time
3. Use asynchronous processing for long-running tasks

## Cost Optimization

### ALB Pricing

- **ALB Hour**: $0.0225 per hour (~$16.20/month)
- **LCU (Load Balancer Capacity Unit)**: $0.008 per LCU-hour
  - New connections: 25 connections/second
  - Active connections: 3,000 connections/minute
  - Processed bytes: 1 GB/hour (HTTP/HTTPS)
  - Rule evaluations: 1,000 rule evaluations/second

### Cost Optimization Tips

**1. Consolidate Target Groups**:
```hcl
# Instead of multiple ALBs:
# - ALB for API ($16.20/month)
# - ALB for Admin ($16.20/month)
# - ALB for Web ($16.20/month)

# Use one ALB with multiple target groups:
target_groups = {
  api   = { ... }
  admin = { ... }
  web   = { ... }
}
# Cost: $16.20/month (savings: $32.40/month)
```

**2. Use CloudFront for Static Content**:
```hcl
# CloudFront caches static content, reducing ALB processed bytes
```

**3. Enable HTTP/2**:
```hcl
enable_http2 = true  # More efficient, reduces LCUs
```

**4. Use Efficient Load Balancing Algorithm**:
```hcl
load_balancing_algorithm_type = "least_outstanding_requests"
# Better resource utilization
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
| architecture_type | Architecture type | `string` | n/a | yes |
| plan_tier | Customer plan tier | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| region | AWS region | `string` | n/a | yes |
| vpc_id | VPC ID | `string` | n/a | yes |
| subnet_ids | Subnet IDs (min 2) | `list(string)` | n/a | yes |
| name | ALB name | `string` | `null` | no |
| load_balancer_type | Load balancer type | `string` | `"application"` | no |
| internal | Internal or internet-facing | `bool` | `false` | no |
| ip_address_type | IP address type | `string` | `"ipv4"` | no |
| security_group_ids | Security group IDs | `list(string)` | `[]` | no |
| enable_deletion_protection | Enable deletion protection | `bool` | `true` | no |
| enable_http2 | Enable HTTP/2 | `bool` | `true` | no |
| idle_timeout | Idle timeout (seconds) | `number` | `60` | no |
| target_groups | Target group configurations | `map(object)` | `{}` | no |
| http_listener | HTTP listener config | `object` | `{...}` | no |
| https_listener | HTTPS listener config | `object` | `{...}` | no |
| enable_access_logs | Enable access logging | `bool` | `true` | no |
| access_logs_bucket | S3 bucket for logs | `string` | `null` | no |
| access_logs_prefix | S3 prefix for logs | `string` | `"alb"` | no |
| web_acl_arn | WAF Web ACL ARN | `string` | `null` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_id | ALB ID |
| alb_arn | ALB ARN |
| alb_arn_suffix | ARN suffix (CloudWatch) |
| alb_name | ALB name |
| dns_name | DNS name (for Route 53) |
| zone_id | Hosted zone ID (for Route 53) |
| vpc_id | VPC ID |
| subnet_ids | Subnet IDs |
| security_group_ids | Security group IDs |
| target_group_arns | Target group ARNs |
| target_group_names | Target group names |
| http_listener_arn | HTTP listener ARN |
| https_listener_arn | HTTPS listener ARN |
| route53_alias_config | Route 53 alias config |
| summary | Configuration summary |

## References

- [AWS ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [ALB Target Groups](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html)
- [ALB Listeners](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html)
- [ALB Access Logs](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html)
- [SSL/TLS Policies](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies)
- [ALB Pricing](https://aws.amazon.com/elasticloadbalancing/pricing/)
- [Terraform aws_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb)
