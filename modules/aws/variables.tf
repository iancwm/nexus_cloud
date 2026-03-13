variable "ami_id" {
  description = "The AMI ID for the Nexus-Cloud workspace instance"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t3.large"
}
