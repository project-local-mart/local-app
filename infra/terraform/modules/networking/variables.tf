variable "environment" {
  type        = string
  description = "Deployment environment: dev, staging, or prod."
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region."
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block. Use 10.0.0.0/16 (dev), 10.1.0.0/16 (staging), 10.2.0.0/16 (prod)."
}

variable "availability_zones" {
  type        = list(string)
  description = "List of AZ names. Provide 2 for dev, 3 for staging/prod."
}

variable "nat_gateway_count" {
  type        = number
  description = "Number of NAT Gateways. 1 for dev/staging, match AZ count for prod."
  validation {
    condition     = var.nat_gateway_count >= 1
    error_message = "nat_gateway_count must be at least 1."
  }
}

variable "enable_vpc_flow_logs" {
  type        = bool
  description = "Whether to enable VPC Flow Logs to CloudWatch."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Common tags from the environment root."
  default     = {}
}
