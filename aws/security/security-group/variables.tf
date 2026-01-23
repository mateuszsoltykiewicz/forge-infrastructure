# ==============================================================================
# Security Group Module - Input Variables
# ==============================================================================

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string

  validation {
    condition     = var.vpc_id != null && var.vpc_id != ""
    error_message = "vpc_id must be provided and cannot be empty"
  }

  # check vpc-id with regex if matches vpc-xxxxxxxx or vpc-xxxxxxxxxxxxxxxxx
  validation {
    condition = can(regex("^vpc-[0-9a-f]{8}([0-9a-f]{9})?$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID (e.g., vpc-xxxxxxxx or vpc-xxxxxxxxxxxxxxxxx)"
  }
}

# ------------------------------------------------------------------------------
# Custom description
# ------------------------------------------------------------------------------

variable "description" {
  description = "Security group description"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# Firewall Tier Configuration (Required for Security Group Chainer)
# ------------------------------------------------------------------------------

variable "ports" {
  description = "List of ports this security group handles (for documentation and chainer discovery)"
  type        = list(number)
  default     = []

  validation {
    condition     = alltrue([for port in var.ports : port >= 0 && port <= 65535])
    error_message = "All ports must be between 0 and 65535"
  }
}

variable "purpose" {
  description = "Specific purpose of the security group for granular identification (e.g., rds-postgresql, redis-cache, control-plane, worker-nodes, logs, kms, lambda). This enables precise security group chaining by distinguishing between resources with the same firewall_tier."
  type        = string

  validation {
    condition     = length(var.purpose) > 0 && length(var.purpose) <= 64
    error_message = "Purpose must be between 1 and 64 characters"
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.purpose))
    error_message = "Purpose must contain only lowercase letters, numbers, and hyphens"
  }
}

# ------------------------------------------------------------------------------
# Security Group Rules (Optional - Can be managed by Chainer)
# ------------------------------------------------------------------------------

variable "ingress_rules" {
  description = <<-EOT
    List of ingress rules to create. If empty, rules will be managed by security-group-chainer.
    
    Example:
    [
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow HTTP from internet"
      }
    ]
  EOT

  type = list(object({
    from_port                = number
    to_port                  = number
    protocol                 = string
    description              = optional(string, "")
    cidr_blocks              = optional(list(string), [])
    ipv6_cidr_blocks         = optional(list(string), [])
    source_security_group_id = optional(string, null)
    self                     = optional(bool, false)
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.ingress_rules :
      contains(["tcp", "udp", "icmp", "icmpv6", "-1"], rule.protocol)
    ])
    error_message = "Protocol must be one of: tcp, udp, icmp, icmpv6, -1 (all)"
  }
}

variable "egress_rules" {
  description = <<-EOT
    List of egress rules to create. If empty, rules will be managed by security-group-chainer.
    
    Example:
    [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outbound"
      }
    ]
  EOT

  type = list(object({
    from_port                = number
    to_port                  = number
    protocol                 = string
    description              = optional(string, "")
    cidr_blocks              = optional(list(string), [])
    ipv6_cidr_blocks         = optional(list(string), [])
    source_security_group_id = optional(string, null)
    self                     = optional(bool, false)
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.egress_rules :
      contains(["tcp", "udp", "icmp", "icmpv6", "-1"], rule.protocol)
    ])
    error_message = "Protocol must be one of: tcp, udp, icmp, icmpv6, -1 (all)"
  }
}

# ------------------------------------------------------------------------------
# Pattern A: Common Tags
# ------------------------------------------------------------------------------

variable "common_prefix" {
  description = "Common prefix for resource naming (used in tags and naming convention)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------------------
# Lifecycle Management
# ------------------------------------------------------------------------------

variable "create_before_destroy" {
  description = "Enable create_before_destroy lifecycle policy (useful for name_prefix resources)"
  type        = bool
  default     = false
}

variable "revoke_rules_on_delete" {
  description = "Revoke all security group rules before deleting the security group"
  type        = bool
  default     = true
}