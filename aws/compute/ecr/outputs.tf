# ==============================================================================
# Outputs - ECR Module
# ==============================================================================

output "repository_url" {
  description = "Full URL of the ECR repository (use for docker push)"
  value       = aws_ecr_repository.main.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.main.arn
}

output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.main.name
}

output "registry_id" {
  description = "Registry ID (AWS account ID)"
  value       = aws_ecr_repository.main.registry_id
}

output "repository_uri_with_tag" {
  description = "Repository URI with :latest tag (ready for Lambda image_uri)"
  value       = "${aws_ecr_repository.main.repository_url}:latest"
}
