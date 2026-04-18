output "vpc_id" {
  value = module.networking.vpc_id
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}

output "ecs_cluster_name" {
  value = module.ecs_cluster.cluster_name
}

output "vault_internal_url" {
  description = "Internal Vault URL for use in application environment variables."
  value       = module.vault.vault_internal_url
}

output "vault_kms_key_id" {
  value = module.vault.vault_kms_key_id
}

output "rds_proxy_endpoint" {
  description = "RDS Proxy endpoint — use as DATABASE_URL host in application config."
  value       = module.database.rds_proxy_endpoint
}

output "api_ecr_repo_url" {
  value = module.ecs_cluster.api_ecr_repo_url
}

output "worker_ecr_repo_url" {
  value = module.ecs_cluster.worker_ecr_repo_url
}

output "ci_role_arn" {
  value = module.iam.vault_task_role_arn
}

output "acm_cert_arn" {
  value = module.dns_certs.acm_cert_arn
}
