output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN — used by all ECS task definitions."
  value       = aws_iam_role.ecs_task_execution.arn
}

output "vault_task_role_arn" {
  description = "Vault ECS task role ARN."
  value       = aws_iam_role.vault_task.arn
}

output "api_task_role_arn" {
  description = "API ECS task role ARN."
  value       = aws_iam_role.api_task.arn
}

output "worker_task_role_arn" {
  description = "Worker ECS task role ARN."
  value       = aws_iam_role.worker_task.arn
}

output "rds_proxy_role_arn" {
  description = "RDS Proxy IAM role ARN — passed into the database module."
  value       = aws_iam_role.rds_proxy.arn
}
