variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "cluster_name" {
  type        = string
  description = "ECS cluster name, e.g. localmart-dev."
}

variable "ecr_repo_names" {
  type        = list(string)
  description = "ECR repository names to create."
  default     = ["vault", "api", "worker"]
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days."
  default     = 30
}

variable "container_insights" {
  type        = bool
  description = "Enable ECS Container Insights."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Common tags from the environment root."
  default     = {}
}
