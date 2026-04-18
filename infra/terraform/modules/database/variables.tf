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

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "isolated_subnet_ids" {
  type        = list(string)
  description = "Isolated subnet IDs for the Aurora cluster."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the RDS Proxy."
}

variable "sg_rds_id" {
  type        = string
  description = "Security group ID for the Aurora cluster."
}

variable "sg_rds_proxy_id" {
  type        = string
  description = "Security group ID for RDS Proxy."
}

variable "cluster_identifier" {
  type        = string
  description = "Aurora cluster identifier, e.g. localmart-dev."
}

variable "database_name" {
  type        = string
  description = "Initial database name."
  default     = "localmart"
}

variable "master_username" {
  type        = string
  description = "Aurora master username."
  default     = "localmart_admin"
}

variable "instance_class" {
  type        = string
  description = "Aurora instance class. db.t4g.medium (dev), db.t4g.large (staging), db.r8g.large (prod)."
}

variable "instance_count" {
  type        = number
  description = "Total Aurora instances (writer + readers). 1 dev, 2 staging, 3 prod."
  validation {
    condition     = var.instance_count >= 1
    error_message = "instance_count must be at least 1."
  }
}

variable "engine_version" {
  type        = string
  description = "Aurora PostgreSQL engine version."
  default     = "16.4"
}

variable "backup_retention_period" {
  type        = number
  description = "Automated backup retention in days."
  default     = 7
}

variable "deletion_protection" {
  type        = bool
  description = "Enable cluster deletion protection. Set true in staging/prod."
  default     = false
}

variable "performance_insights_enabled" {
  type        = bool
  description = "Enable Performance Insights on Aurora instances."
  default     = false
}

variable "enable_proxy" {
  type        = bool
  description = "Whether to create an RDS Proxy in front of the cluster."
  default     = true
}

variable "proxy_iam_role_arn" {
  type        = string
  description = "IAM role ARN for RDS Proxy to read Secrets Manager."
}

variable "tags" {
  type        = map(string)
  description = "Common tags from the environment root."
  default     = {}
}
