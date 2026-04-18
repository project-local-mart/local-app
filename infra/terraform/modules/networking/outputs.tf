output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block."
  value       = aws_vpc.main.cidr_block
}

output "availability_zones" {
  description = "Availability zones used by this VPC."
  value       = var.availability_zones
}

output "public_subnet_ids" {
  description = "Public subnet IDs (one per AZ)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (one per AZ). Used by ECS tasks, Vault, EFS, RDS Proxy."
  value       = aws_subnet.private[*].id
}

output "isolated_subnet_ids" {
  description = "Isolated subnet IDs (one per AZ). Used by Aurora cluster — no route to internet."
  value       = aws_subnet.isolated[*].id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs."
  value       = aws_nat_gateway.main[*].id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID."
  value       = aws_internet_gateway.main.id
}

output "sg_vault_alb_id" {
  description = "Security group ID for the Vault internal ALB."
  value       = aws_security_group.vault_alb.id
}

output "sg_vault_task_id" {
  description = "Security group ID for Vault ECS tasks."
  value       = aws_security_group.vault_task.id
}

output "sg_api_task_id" {
  description = "Security group ID for API ECS tasks."
  value       = aws_security_group.api_task.id
}

output "sg_worker_task_id" {
  description = "Security group ID for worker ECS tasks."
  value       = aws_security_group.worker_task.id
}

output "sg_rds_proxy_id" {
  description = "Security group ID for RDS Proxy."
  value       = aws_security_group.rds_proxy.id
}

output "sg_rds_id" {
  description = "Security group ID for Aurora cluster."
  value       = aws_security_group.rds.id
}

output "vpc_endpoint_s3_id" {
  description = "S3 Gateway VPC endpoint ID."
  value       = aws_vpc_endpoint.s3.id
}

output "vpc_endpoint_ecr_dkr_id" {
  description = "ECR DKR interface VPC endpoint ID."
  value       = aws_vpc_endpoint.interface["ecr.dkr"].id
}
