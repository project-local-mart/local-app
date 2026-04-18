output "cluster_arn" {
  description = "ECS cluster ARN."
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.main.name
}

output "ecr_repo_urls" {
  description = "Map of repo name → ECR repository URL."
  value       = { for k, v in aws_ecr_repository.repos : k => v.repository_url }
}

output "vault_ecr_repo_url" {
  description = "ECR repository URL for the Vault image."
  value       = aws_ecr_repository.repos["vault"].repository_url
}

output "api_ecr_repo_url" {
  description = "ECR repository URL for the API image."
  value       = aws_ecr_repository.repos["api"].repository_url
}

output "worker_ecr_repo_url" {
  description = "ECR repository URL for the worker image."
  value       = aws_ecr_repository.repos["worker"].repository_url
}

output "vault_log_group_name" {
  description = "CloudWatch log group name for Vault."
  value       = aws_cloudwatch_log_group.service_logs["vault"].name
}

output "api_log_group_name" {
  description = "CloudWatch log group name for the API."
  value       = aws_cloudwatch_log_group.service_logs["api"].name
}

output "worker_log_group_name" {
  description = "CloudWatch log group name for the worker."
  value       = aws_cloudwatch_log_group.service_logs["worker"].name
}
