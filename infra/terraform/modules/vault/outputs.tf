output "vault_alb_dns_name" {
  description = "Vault internal ALB DNS name."
  value       = aws_lb.vault.dns_name
}

output "vault_internal_url" {
  description = "Internal URL for reaching Vault from other services."
  value       = "http://vault.${var.internal_domain}:8200"
}

output "vault_kms_key_arn" {
  description = "KMS key ARN used for Vault auto-unseal. Pass to the IAM module."
  value       = aws_kms_key.vault_unseal.arn
}

output "vault_kms_key_id" {
  description = "KMS key ID used for Vault auto-unseal."
  value       = aws_kms_key.vault_unseal.key_id
}

output "efs_file_system_id" {
  description = "EFS file system ID backing Vault Raft storage."
  value       = aws_efs_file_system.vault.id
}

output "vault_alb_arn" {
  description = "Vault internal ALB ARN — use for WAF association in Tier 4."
  value       = aws_lb.vault.arn
}

output "vault_service_name" {
  description = "ECS service name for Vault."
  value       = aws_ecs_service.vault.name
}

output "vault_task_definition_arn" {
  description = "Latest Vault ECS task definition ARN."
  value       = aws_ecs_task_definition.vault.arn
}
