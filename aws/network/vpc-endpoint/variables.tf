# ==============================================================================
# VPC Endpoint Module - Variables
# ==============================================================================
# This file defines input variables for the VPC endpoint module.
# ==============================================================================

# ------------------------------------------------------------------------------
# Firewall / Communication Tier
# ------------------------------------------------------------------------------
variable "firewall_tier" {
  description = "Communication tier for resource naming and organization"
  type        = string
  default     = "VPCEndpoints"
}

variable "firewall_type" {
  description = "Firewall type for resource naming and organization"
  type        = string
  default     = "Slave"
}

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
}

# ------------------------------------------------------------------------------
# VPC Configuration
# ------------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC where the endpoint will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]{8,}$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID format (vpc-xxxxxxxx)"
  }
}

# ------------------------------------------------------------------------------
# Endpoint Configuration
# ------------------------------------------------------------------------------

variable "service_name" {
  description = "AWS service name for the endpoint (e.g., 's3', 'ec2', 'dynamodb', 'com.amazonaws.vpce.region.vpce-svc-xxxxx' for PrivateLink)"
  type        = string
}

# ------------------------------------------------------------------------------
# Network Configuration (Interface & GatewayLoadBalancer endpoints)
# ------------------------------------------------------------------------------

variable "subnet_ids" {
  description = "List of subnet IDs for Interface/GatewayLoadBalancer endpoints (required for Interface/GWLB, ignored for Gateway)"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.subnet_ids : can(regex("^subnet-[a-z0-9]{8,}$", id))])
    error_message = "All subnet_ids must be valid subnet ID format (subnet-xxxxxxxx)"
  }
}

# ------------------------------------------------------------------------------
# Network Configuration (Gateway endpoints)
# ------------------------------------------------------------------------------

variable "route_table_ids" {
  description = "List of route table IDs for Gateway endpoints (required for Gateway endpoints like S3 and DynamoDB, ignored for Interface endpoints)"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.route_table_ids : can(regex("^rtb-[a-z0-9]{8,}$", id))])
    error_message = "All route_table_ids must be valid route table ID format (rtb-xxxxxxxx)"
  }
}

# ------------------------------------------------------------------------------
# DNS Configuration
# ------------------------------------------------------------------------------

variable "dns_options" {
  description = "DNS options for the endpoint"
  type = object({
    dns_record_ip_type                             = optional(string, "ipv4") # ipv4, dualstack, service-defined, ipv6
    private_dns_only_for_inbound_resolver_endpoint = optional(bool, false)
  })
  default = {
    dns_record_ip_type = "ipv4"
  }
}

# ------------------------------------------------------------------------------
# Policy Configuration
# ------------------------------------------------------------------------------

variable "policy" {
  description = "IAM policy document (JSON) to attach to the endpoint (restricts access to specific resources/actions)"
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# Tags
# ------------------------------------------------------------------------------

variable "common_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------------------
# Common Prefix for multi tenancy and naming concention
# ------------------------------------------------------------------------------

variable "common_prefix" {
  description = "Prefix for common tags"
  type        = string
  default     = "VPCEndpoint"
}
