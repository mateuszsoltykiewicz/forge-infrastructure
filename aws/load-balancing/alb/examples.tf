# ==============================================================================
# ALB Module - Example Configurations
# ==============================================================================
# This file demonstrates different multi-tenant deployment scenarios.
# Uncomment ONE example at a time to test the module.
# ==============================================================================

# ------------------------------------------------------------------------------
# Example 1: Shared Platform ALB (No Customer/Project Isolation)
# ------------------------------------------------------------------------------
# Use case: Single ALB shared across all customers/projects
# Naming: forge-{environment}-alb
# Tags: No Customer or Project tags
# ------------------------------------------------------------------------------

# module "alb_shared" {
#   source = "./forge-infrastructure/aws/load-balancing/alb"
#
#   # Environment & Workspace (required)
#   environment = "production"
#   workspace   = "forge-platform"
#
#   # No customer_name or project_name = shared ALB
#
#   # ALB Configuration
#   load_balancer_type = "application"
#   internal           = false
#   ip_address_type    = "ipv4"
#
#   # Network (auto-discovery and auto-creation)
#   alb_subnet_az_count    = 3
#   alb_subnet_newbits     = 8  # /24 subnets from VPC CIDR
#   alb_subnet_netnum_start = 10
#
#   # EKS Integration (auto-discovery)
#   # eks_cluster_name is optional - will auto-discover if not provided
#
#   # ALB Attributes
#   enable_deletion_protection       = true
#   enable_http2                     = true
#   enable_cross_zone_load_balancing = true
#   idle_timeout                     = 60
#   desync_mitigation_mode           = "defensive"
#   drop_invalid_header_fields       = true
#   preserve_host_header             = true
#
#   # Access Logs
#   enable_access_logs   = true
#   access_logs_bucket   = "forge-alb-logs"
#   access_logs_prefix   = "production/shared"
#
#   # Target Groups
#   target_groups = {
#     api = {
#       port                          = 8080
#       protocol                      = "HTTP"
#       target_type                   = "ip"
#       deregistration_delay          = 30
#       slow_start                    = 30
#       load_balancing_algorithm_type = "round_robin"
#
#       health_check = {
#         enabled             = true
#         interval            = 30
#         path                = "/health"
#         port                = "traffic-port"
#         protocol            = "HTTP"
#         timeout             = 5
#         healthy_threshold   = 2
#         unhealthy_threshold = 2
#         matcher             = "200"
#       }
#     }
#   }
#
#   # HTTP Listener (redirect to HTTPS)
#   http_listener = {
#     enabled        = true
#     port           = 80
#     redirect_https = true
#   }
#
#   # HTTPS Listener
#   https_listener = {
#     enabled          = true
#     port             = 443
#     certificate_arn  = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxx"
#     ssl_policy       = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#     target_group_key = "api"
#   }
#
#   # WAF (optional)
#   web_acl_arn = null
#
#   # Tags
#   tags = {
#     Owner = "Platform-Team"
#   }
# }

# ------------------------------------------------------------------------------
# Example 2: Customer-Dedicated ALB (Customer Isolation)
# ------------------------------------------------------------------------------
# Use case: Dedicated ALB per customer
# Naming: forge-{environment}-{customer_name}-alb
# Tags: Customer = {customer_name}
# ------------------------------------------------------------------------------

# module "alb_customer_acme" {
#   source = "./forge-infrastructure/aws/load-balancing/alb"
#
#   # Environment & Workspace (required)
#   environment = "production"
#   workspace   = "forge-platform"
#
#   # Customer isolation
#   customer_id   = "cust-001"
#   customer_name = "acme"
#   plan_tier     = "enterprise"
#   # No project_name = customer-level ALB
#
#   # ALB Configuration
#   load_balancer_type = "application"
#   internal           = false
#   ip_address_type    = "dualstack"  # IPv4 + IPv6
#
#   # Network (auto-discovery and auto-creation)
#   alb_subnet_az_count    = 3
#   alb_subnet_newbits     = 8
#   alb_subnet_netnum_start = 20
#
#   # EKS Integration (manual specification)
#   eks_cluster_name = "forge-production-acme-eks"
#
#   # ALB Attributes
#   enable_deletion_protection       = true
#   enable_http2                     = true
#   enable_cross_zone_load_balancing = true
#   idle_timeout                     = 120
#   desync_mitigation_mode           = "strictest"
#   drop_invalid_header_fields       = true
#   preserve_host_header             = true
#
#   # Access Logs
#   enable_access_logs   = true
#   access_logs_bucket   = "forge-alb-logs"
#   access_logs_prefix   = "production/acme"
#
#   # Target Groups
#   target_groups = {
#     web = {
#       port                          = 3000
#       protocol                      = "HTTP"
#       target_type                   = "ip"
#       deregistration_delay          = 60
#       slow_start                    = 60
#       load_balancing_algorithm_type = "least_outstanding_requests"
#
#       health_check = {
#         enabled             = true
#         interval            = 15
#         path                = "/"
#         port                = "traffic-port"
#         protocol            = "HTTP"
#         timeout             = 5
#         healthy_threshold   = 2
#         unhealthy_threshold = 3
#         matcher             = "200-299"
#       }
#
#       stickiness = {
#         enabled         = true
#         type            = "lb_cookie"
#         cookie_duration = 86400  # 24 hours
#       }
#     }
#
#     api = {
#       port                          = 8080
#       protocol                      = "HTTP"
#       target_type                   = "ip"
#       deregistration_delay          = 30
#       load_balancing_algorithm_type = "round_robin"
#
#       health_check = {
#         enabled             = true
#         interval            = 30
#         path                = "/api/health"
#         port                = "traffic-port"
#         protocol            = "HTTP"
#         timeout             = 5
#         healthy_threshold   = 2
#         unhealthy_threshold = 2
#         matcher             = "200"
#       }
#     }
#   }
#
#   # HTTP Listener (redirect to HTTPS)
#   http_listener = {
#     enabled        = true
#     port           = 80
#     redirect_https = true
#   }
#
#   # HTTPS Listener
#   https_listener = {
#     enabled          = true
#     port             = 443
#     certificate_arn  = "arn:aws:acm:us-east-1:123456789012:certificate/acme-cert"
#     ssl_policy       = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#     target_group_key = "web"
#   }
#
#   # WAF
#   web_acl_arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/acme-waf/xxxxx"
#
#   # Tags
#   tags = {
#     Owner      = "Customer-ACME"
#     Compliance = "SOC2"
#   }
# }

# ------------------------------------------------------------------------------
# Example 3: Project-Isolated ALB (Customer + Project Isolation)
# ------------------------------------------------------------------------------
# Use case: Dedicated ALB per customer project
# Naming: forge-{environment}-{customer_name}-{project_name}-alb
# Tags: Customer = {customer_name}, Project = {project_name}
# ------------------------------------------------------------------------------

# module "alb_project_acme_webapp" {
#   source = "./forge-infrastructure/aws/load-balancing/alb"
#
#   # Environment & Workspace (required)
#   environment = "staging"
#   workspace   = "forge-platform"
#
#   # Project-level isolation
#   customer_id   = "cust-001"
#   customer_name = "acme"
#   project_name  = "webapp"
#   plan_tier     = "pro"
#
#   # ALB Configuration
#   load_balancer_type = "application"
#   internal           = false
#   ip_address_type    = "ipv4"
#
#   # Network (auto-discovery and auto-creation)
#   alb_subnet_az_count    = 2
#   alb_subnet_newbits     = 8
#   alb_subnet_netnum_start = 30
#
#   # EKS Integration (auto-discovery by tags)
#   # Will find EKS cluster tagged with Customer=acme, Project=webapp
#
#   # ALB Attributes
#   enable_deletion_protection       = false  # Staging environment
#   enable_http2                     = true
#   enable_cross_zone_load_balancing = true
#   idle_timeout                     = 60
#   desync_mitigation_mode           = "defensive"
#   drop_invalid_header_fields       = true
#   preserve_host_header             = true
#
#   # Access Logs
#   enable_access_logs   = true
#   access_logs_bucket   = "forge-alb-logs"
#   access_logs_prefix   = "staging/acme-webapp"
#
#   # Target Groups
#   target_groups = {
#     app = {
#       port                          = 8000
#       protocol                      = "HTTP"
#       target_type                   = "ip"
#       deregistration_delay          = 30
#       slow_start                    = 0
#       load_balancing_algorithm_type = "round_robin"
#
#       health_check = {
#         enabled             = true
#         interval            = 30
#         path                = "/healthz"
#         port                = "traffic-port"
#         protocol            = "HTTP"
#         timeout             = 5
#         healthy_threshold   = 2
#         unhealthy_threshold = 2
#         matcher             = "200"
#       }
#     }
#   }
#
#   # HTTP Listener (redirect to HTTPS)
#   http_listener = {
#     enabled        = true
#     port           = 80
#     redirect_https = true
#   }
#
#   # HTTPS Listener
#   https_listener = {
#     enabled          = true
#     port             = 443
#     certificate_arn  = "arn:aws:acm:us-east-1:123456789012:certificate/webapp-staging"
#     ssl_policy       = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#     target_group_key = "app"
#   }
#
#   # Tags
#   tags = {
#     Owner      = "Customer-ACME"
#     CostCenter = "ACME-WebApp"
#   }
# }

# ------------------------------------------------------------------------------
# Example 4: Internal ALB (VPC-only access)
# ------------------------------------------------------------------------------
# Use case: Internal ALB for backend services
# ------------------------------------------------------------------------------

# module "alb_internal" {
#   source = "./forge-infrastructure/aws/load-balancing/alb"
#
#   # Environment & Workspace (required)
#   environment = "production"
#   workspace   = "forge-platform"
#
#   # Customer context
#   customer_name = "platform"
#   project_name  = "internal-services"
#
#   # ALB Configuration (INTERNAL)
#   load_balancer_type = "application"
#   internal           = true  # Internal ALB
#   ip_address_type    = "ipv4"
#
#   # Network (auto-discovery and auto-creation)
#   alb_subnet_az_count    = 2
#   alb_subnet_newbits     = 8
#   alb_subnet_netnum_start = 40
#
#   # EKS Integration
#   eks_cluster_name = "forge-production-eks"
#
#   # ALB Attributes
#   enable_deletion_protection       = true
#   enable_http2                     = true
#   enable_cross_zone_load_balancing = true
#   idle_timeout                     = 60
#   desync_mitigation_mode           = "defensive"
#   drop_invalid_header_fields       = true
#   preserve_host_header             = true
#
#   # Access Logs
#   enable_access_logs   = false  # Internal ALB, no access logs needed
#
#   # Target Groups
#   target_groups = {
#     backend = {
#       port                          = 8080
#       protocol                      = "HTTP"
#       target_type                   = "ip"
#       deregistration_delay          = 30
#       load_balancing_algorithm_type = "round_robin"
#
#       health_check = {
#         enabled             = true
#         interval            = 30
#         path                = "/health"
#         port                = "traffic-port"
#         protocol            = "HTTP"
#         timeout             = 5
#         healthy_threshold   = 2
#         unhealthy_threshold = 2
#         matcher             = "200"
#       }
#     }
#   }
#
#   # HTTP Listener (no redirect, direct forwarding)
#   http_listener = {
#     enabled          = true
#     port             = 80
#     redirect_https   = false
#     target_group_key = "backend"
#   }
#
#   # No HTTPS for internal services (optional)
#   https_listener = {
#     enabled = false
#   }
#
#   # Tags
#   tags = {
#     Owner = "Platform-Team"
#     Type  = "Internal"
#   }
# }

# ==============================================================================
# Usage Notes
# ==============================================================================
#
# 1. Zero-Config Auto-Discovery:
#    - VPC: Auto-discovered by tags (Workspace, Environment, Customer, Project)
#    - EKS: Auto-discovered by tags (or specify eks_cluster_name manually)
#    - Subnets: Created automatically from VPC CIDR (public subnets for ALB)
#    - Security Groups: Created automatically with EKS integration
#    - Internet Gateway: Auto-discovered for public subnet routing
#
# 2. Multi-Tenant Naming Patterns:
#    - Shared: forge-{environment}-alb
#    - Customer: forge-{environment}-{customer_name}-alb
#    - Project: forge-{environment}-{customer_name}-{project_name}-alb
#
# 3. Required AWS Resources (must exist):
#    - VPC with appropriate tags
#    - Internet Gateway (for public ALBs)
#    - ACM certificates for HTTPS listeners
#    - S3 bucket for access logs (if enabled)
#    - EKS cluster (optional, for security group integration)
#
# 4. Created Resources:
#    - Application Load Balancer
#    - Public ALB subnets (one per AZ)
#    - Route table with IGW route
#    - Route table associations
#    - Security group with HTTP/HTTPS ingress, EKS egress
#    - Target groups (as configured)
#    - Listeners (HTTP, HTTPS)
#    - CloudWatch dashboard
#    - CloudWatch alarms (6 metrics)
#    - WAF association (if web_acl_arn provided)
#
# 5. Target Group Types:
#    - instance: EC2 instances
#    - ip: IP addresses (for EKS pods, Fargate)
#    - lambda: Lambda functions
#    - alb: Another ALB
#
# 6. SSL Policies (HTTPS):
#    - ELBSecurityPolicy-TLS13-1-2-2021-06 (recommended, TLS 1.3 + 1.2)
#    - ELBSecurityPolicy-TLS13-1-0-2021-06 (TLS 1.3 + 1.2 + 1.0)
#    - ELBSecurityPolicy-2016-08 (legacy, TLS 1.2 + 1.1 + 1.0)
#
# ==============================================================================
