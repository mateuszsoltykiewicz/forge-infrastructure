# ==============================================================================
# Outputs - Lambda Log Transformer Module
# ==============================================================================

output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.log_transformer.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.log_transformer.arn
}

output "invoke_arn" {
  description = "Lambda function invoke ARN (use in Firehose processor configuration)"
  value       = aws_lambda_function.log_transformer.invoke_arn
}

output "qualified_arn" {
  description = "Lambda function qualified ARN (includes version)"
  value       = aws_lambda_function.log_transformer.qualified_arn
}

output "version" {
  description = "Latest published version"
  value       = aws_lambda_function.log_transformer.version
}

output "role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_execution.arn
}

output "role_name" {
  description = "Lambda execution role name"
  value       = aws_iam_role.lambda_execution.name
}

output "log_group_name" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "log_group_arn" {
  description = "CloudWatch Log Group ARN"
  value       = aws_cloudwatch_log_group.lambda_logs.arn
}

# ------------------------------------------------------------------------------
# Metadata for Monitoring/Debugging
# ------------------------------------------------------------------------------

output "image_uri" {
  description = "Container image URI used by Lambda"
  value       = var.image_uri
}

output "timeout" {
  description = "Lambda timeout in seconds"
  value       = var.timeout
}

output "memory_size" {
  description = "Lambda memory size in MB"
  value       = var.memory_size
}

output "reserved_concurrent_executions" {
  description = "Reserved concurrent executions (null = unreserved)"
  value       = var.reserved_concurrent_executions
}
