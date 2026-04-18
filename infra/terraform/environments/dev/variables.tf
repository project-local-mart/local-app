variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "root_domain" {
  type        = string
  description = "Public apex domain, e.g. localmart.app."
}

variable "state_bucket_arn" {
  type        = string
  description = "ARN of the Terraform state S3 bucket (from bootstrap output)."
}

variable "lock_table_arn" {
  type        = string
  description = "ARN of the DynamoDB lock table (from bootstrap output)."
}
