# ==============================================================================
# Internet Gateway Module - Outputs
# ==============================================================================
# Exposes Internet Gateway attributes for use by other modules.
# ==============================================================================

# ------------------------------------------------------------------------------
# Internet Gateway Outputs
# ------------------------------------------------------------------------------

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "internet_gateway_arn" {
  description = "ARN of the Internet Gateway"
  value       = aws_internet_gateway.this.arn
}

output "vpc_id" {
  description = "VPC ID that the Internet Gateway is attached to"
  value       = aws_internet_gateway.this.vpc_id
}
