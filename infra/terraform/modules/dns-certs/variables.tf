variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "root_domain" {
  type        = string
  description = "Public apex domain, e.g. localmart.app."
}

variable "internal_domain" {
  type        = string
  description = "Private hosted zone domain, e.g. localmart.internal."
  default     = "localmart.internal"
}

variable "vpc_id" {
  type        = string
  description = "VPC to associate the private hosted zone with."
}

variable "tags" {
  type        = map(string)
  description = "Common tags from the environment root."
  default     = {}
}
