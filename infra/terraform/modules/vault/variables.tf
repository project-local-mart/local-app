variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "aws_region" {
  type        = string
  description = "AWS region."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for ECS tasks and EFS mount targets."
}

variable "sg_vault_alb_id" {
  type        = string
  description = "Security group ID for the Vault internal ALB."
}

variable "sg_vault_task_id" {
  type        = string
  description = "Security group ID for Vault ECS tasks."
}

variable "task_execution_role_arn" {
  type        = string
  description = "ECS task execution role ARN."
}

variable "task_role_arn" {
  type        = string
  description = "Vault-specific ECS task role ARN."
}

variable "ecs_cluster_arn" {
  type        = string
  description = "ECS cluster ARN."
}

variable "ecs_cluster_name" {
  type        = string
  description = "ECS cluster name."
}

variable "log_group_name" {
  type        = string
  description = "CloudWatch log group name for Vault container output."
}

variable "vault_ecr_repo_url" {
  type        = string
  description = "ECR repository URL for the Vault image."
}

variable "vault_image_tag" {
  type        = string
  description = "Vault image tag to deploy."
  default     = "1.17"
}

variable "vault_task_count" {
  type        = number
  description = "Number of Vault ECS tasks. Use 1 for dev/staging, 3 for prod HA."
  default     = 1
}

variable "vault_cpu" {
  type        = number
  description = "Fargate CPU units for the Vault task."
  default     = 512
}

variable "vault_memory" {
  type        = number
  description = "Fargate memory MiB for the Vault task."
  default     = 1024
}

variable "efs_throughput_mode" {
  type        = string
  description = "EFS throughput mode: bursting or provisioned."
  default     = "bursting"
  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.efs_throughput_mode)
    error_message = "efs_throughput_mode must be bursting, provisioned, or elastic."
  }
}

variable "private_zone_id" {
  type        = string
  description = "Route53 private hosted zone ID for the vault.localmart.internal record."
}

variable "internal_domain" {
  type        = string
  description = "Internal domain, e.g. localmart.internal."
  default     = "localmart.internal"
}

variable "acm_cert_arn" {
  type        = string
  description = "ACM wildcard certificate ARN for the Vault ALB HTTPS listener."
}

variable "tags" {
  type        = map(string)
  description = "Common tags from the environment root."
  default     = {}
}
