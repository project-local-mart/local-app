output "cluster_endpoint" {
  description = "Aurora writer endpoint."
  value       = aws_rds_cluster.main.endpoint
}

output "cluster_reader_endpoint" {
  description = "Aurora reader endpoint (load-balanced across read replicas)."
  value       = aws_rds_cluster.main.reader_endpoint
}

output "cluster_arn" {
  description = "Aurora cluster ARN."
  value       = aws_rds_cluster.main.arn
}

output "cluster_identifier" {
  description = "Aurora cluster identifier."
  value       = aws_rds_cluster.main.cluster_identifier
}

output "rds_proxy_endpoint" {
  description = "RDS Proxy endpoint — primary connection string for applications."
  value       = var.enable_proxy ? aws_db_proxy.main[0].endpoint : aws_rds_cluster.main.endpoint
}

output "rds_proxy_arn" {
  description = "RDS Proxy ARN."
  value       = var.enable_proxy ? aws_db_proxy.main[0].arn : null
}

output "database_kms_key_arn" {
  description = "KMS key ARN for RDS encryption. Pass to the IAM module."
  value       = aws_kms_key.rds.arn
}

output "database_kms_key_id" {
  description = "KMS key ID for RDS encryption."
  value       = aws_kms_key.rds.key_id
}

output "db_subnet_group_name" {
  description = "DB subnet group name."
  value       = aws_db_subnet_group.main.name
}

output "secret_arn" {
  description = "Secrets Manager ARN holding the Aurora master credentials."
  value       = aws_secretsmanager_secret.db_master.arn
  sensitive   = true
}

output "database_name" {
  description = "Initial database name."
  value       = aws_rds_cluster.main.database_name
}
