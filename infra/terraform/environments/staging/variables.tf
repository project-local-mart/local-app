variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "root_domain" {
  type = string
}

variable "state_bucket_arn" {
  type = string
}

variable "lock_table_arn" {
  type = string
}
