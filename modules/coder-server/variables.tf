variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the Coder server (e.g., coder.example.com)"
  type        = string
}

variable "route53_zone_id" {
  description = "The Route53 Hosted Zone ID for the domain"
  type        = string
}

variable "instance_type" {
  description = "Instance type for Coder server"
  type        = string
  default     = "t3.medium"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "nexus-coder-server"
}
