# ==============================================================================
# Subnet Module - Outputs
# ==============================================================================

output "subnet_ids" {
  description = "List of created subnet IDs"
  value       = aws_subnet.this[*].id
}

output "subnet_arns" {
  description = "List of subnet ARNs"
  value       = aws_subnet.this[*].arn
}

output "subnet_cidrs" {
  description = "List of subnet CIDR blocks"
  value       = aws_subnet.this[*].cidr_block
}

output "availability_zones" {
  description = "List of availability zones"
  value       = aws_subnet.this[*].availability_zone
}

output "route_table_ids" {
  description = "List of route table IDs (if created)"
  value       = aws_route_table.this[*].id
}

output "subnet_map" {
  description = "Map of AZ to subnet ID"
  value = {
    for idx, az in var.availability_zones :
    az => aws_subnet.this[idx].id
  }
}