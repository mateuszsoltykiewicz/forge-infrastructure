#
# Application Load Balancer Module - Local Variables
# Purpose: Computed values and validation logic
#

locals {
  # ========================================
  # Architecture Detection
  # ========================================

  is_shared_architecture = var.architecture_type == "shared"

  # ========================================
  # ALB Naming
  # ========================================

  # ALB name (max 32 characters)
  alb_name = var.name != null ? var.name : (
    local.is_shared_architecture
    ? substr("forge-${var.environment}-alb", 0, 32)
    : substr("${var.customer_name}-${var.region}-alb", 0, 32)
  )

  # Target group name prefix (max 32 characters, leave room for hash)
  tg_name_prefix = local.is_shared_architecture ? "forge-${var.environment}" : "${var.customer_name}-${var.region}"

  # ========================================
  # Listener Configuration
  # ========================================

  # HTTP listener enabled
  http_listener_enabled = var.http_listener.enabled

  # HTTPS listener enabled
  https_listener_enabled = var.https_listener.enabled

  # HTTPS requires certificate
  https_certificate_valid = !local.https_listener_enabled || var.https_listener.certificate_arn != null

  # ========================================
  # Access Logs Configuration
  # ========================================

  # Access logs validation
  access_logs_valid = !var.enable_access_logs || var.access_logs_bucket != null

  # Access logs configuration
  access_logs_config = var.enable_access_logs ? {
    bucket  = var.access_logs_bucket
    prefix  = var.access_logs_prefix
    enabled = true
  } : null

  # ========================================
  # Target Groups Validation
  # ========================================

  # Validate target group protocols
  valid_protocols = ["HTTP", "HTTPS", "TCP", "TLS", "UDP", "TCP_UDP", "GENEVE"]
  
  target_groups_protocol_valid = alltrue([
    for tg_key, tg in var.target_groups :
    contains(local.valid_protocols, tg.protocol)
  ])

  # Validate target types
  valid_target_types = ["instance", "ip", "lambda", "alb"]
  
  target_groups_type_valid = alltrue([
    for tg_key, tg in var.target_groups :
    contains(local.valid_target_types, tg.target_type)
  ])

  # ========================================
  # Auto-Generated Comment
  # ========================================

  alb_type_description = var.internal ? "Internal" : "Internet-facing"
  
  auto_comment = "${local.alb_type_description} Application Load Balancer for ${var.environment}"

  # ========================================
  # Resource Tags
  # ========================================

  # Base tags applied to all resources
  base_tags = {
    Module      = "alb"
    ManagedBy   = "terraform"
    Environment = var.environment
    Region      = var.region
  }

  # Customer-specific tags
  customer_tags = {
    CustomerId       = var.customer_id
    CustomerName     = var.customer_name
    ArchitectureType = var.architecture_type
    PlanTier         = var.plan_tier
  }

  # ALB-specific tags
  alb_tags = {
    Name        = local.alb_name
    Type        = var.load_balancer_type
    Visibility  = var.internal ? "internal" : "internet-facing"
    IPAddressType = var.ip_address_type
  }

  # Merge all tags
  all_tags = merge(
    local.base_tags,
    local.customer_tags,
    local.alb_tags,
    var.tags
  )

  # Target group tags
  target_group_base_tags = merge(
    local.base_tags,
    local.customer_tags,
    var.tags
  )
}
