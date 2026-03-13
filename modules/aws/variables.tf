variable "ami_id" {
  description = "The AMI ID for the Nexus-Cloud workspace instance"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t3.large"
}

variable "user_id" {
  description = "The Coder user ID"
  type        = string
}

variable "ssh_public_key" {
  description = "The public SSH key to authorize on the workspace instance."
  type        = string
  default     = ""
}
