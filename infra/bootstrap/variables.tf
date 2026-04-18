variable "aws_region" {
  type        = string
  description = "Primary AWS region."
  default     = "us-east-1"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for Terraform remote state."
}

variable "lock_table_name" {
  type        = string
  description = "DynamoDB table name for Terraform state locking."
  default     = "localmart-terraform-locks"
}

variable "cloudtrail_bucket_name" {
  type        = string
  description = "S3 bucket name for CloudTrail logs."
}

variable "cloudtrail_name" {
  type        = string
  description = "CloudTrail trail name."
  default     = "localmart-audit"
}

variable "github_org" {
  type        = string
  description = "GitHub organisation name used for OIDC trust on the CI IAM role."
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name used for OIDC trust on the CI IAM role."
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to merge onto all resources."
  default     = {}
}
