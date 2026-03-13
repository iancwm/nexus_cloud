variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "The AMI ID for the Nexus-Cloud workspace instance (defaults to latest Ubuntu 24.04)"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t3.large"
}

variable "ssh_public_key" {
  description = "The public SSH key to authorize on the workspace instance."
  type        = string
  default     = ""
}

# --- Hosted Coder Server Configuration ---

variable "deploy_coder_server" {
  description = "Whether to deploy a hosted Coder server on AWS"
  type        = bool
  default     = false
}

variable "coder_domain_name" {
  description = "The domain name for the Coder server"
  type        = string
  default     = ""
}

variable "coder_route53_zone_id" {
  description = "The Route53 Hosted Zone ID for the Coder domain"
  type        = string
  default     = ""
}
