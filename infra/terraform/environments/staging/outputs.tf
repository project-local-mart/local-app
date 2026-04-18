output "vpc_id" { value = module.networking.vpc_id }
output "ecs_cluster_name" { value = module.ecs_cluster.cluster_name }
output "vault_internal_url" { value = module.vault.vault_internal_url }
output "rds_proxy_endpoint" { value = module.database.rds_proxy_endpoint }
output "api_ecr_repo_url" { value = module.ecs_cluster.api_ecr_repo_url }
output "worker_ecr_repo_url" { value = module.ecs_cluster.worker_ecr_repo_url }
output "acm_cert_arn" { value = module.dns_certs.acm_cert_arn }
