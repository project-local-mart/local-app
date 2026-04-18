variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "aws_region" {
  type        = string
  description = "AWS region."
}

variable "aws_account_id" {
  type        = string
  description = "AWS account ID."
}

variable "ecs_cluster_arn" {
  type        = string
  description = "ECS cluster ARN, used to scope ECS permissions."
}

variable "vault_kms_key_arn" {
  type        = string
  description = "ARN of the Vault auto-unseal KMS key."
}

variable "database_kms_key_arn" {
  type        = string
  description = "ARN of the RDS encryption KMS key."
}

variable "state_bucket_arn" {
  type        = string
  description = "ARN of the Terraform state S3 bucket (for CI role)."
}

variable "lock_table_arn" {
  type        = string
  description = "ARN of the DynamoDB state lock table (for CI role)."
}

variable "ecr_repo_arns" {
  type        = list(string)
  description = "ECR repository ARNs for the task execution role pull permission."
}

variable "tags" {
  type        = map(string)
  description = "Common tags from the environment root."
  default     = {}
}
