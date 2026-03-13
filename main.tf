terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 0.13.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "coder" {}

# --- Coder Parameters ---

data "coder_parameter" "region" {
  name         = "region"
  display_name = "AWS Region"
  description  = "The AWS region to deploy into"
  default      = "ap-northeast-1"
  icon         = "/icon/aws.svg"
  mutable      = false
}

provider "aws" {
  region = coalesce(data.coder_parameter.region.value, var.aws_region)
}

data "coder_workspace" "me" {}

variable "user_id_override" {
  description = "A safe ID for resource naming (fallback if Coder is not used)"
  type        = string
  default     = "local-user"
}

module "nexus_aws" {
  source         = "./modules/aws"
  ami_id         = var.ami_id
  instance_type  = var.instance_type
  user_id        = try(data.coder_workspace.me.owner, var.user_id_override)
  workspace_name = try(data.coder_workspace.me.name, "default")
  ssh_public_key = var.ssh_public_key
  aws_region     = coalesce(data.coder_parameter.region.value, var.aws_region)
}

# --- Hosted Coder Server ---

module "coder_server" {
  count           = var.deploy_coder_server ? 1 : 0
  source          = "./modules/coder-server"
  aws_region      = var.aws_region
  domain_name     = var.coder_domain_name
  route53_zone_id = var.coder_route53_zone_id
}

output "coder_server_url" {
  value = var.deploy_coder_server ? module.coder_server[0].coder_url : "not-deployed"
}

output "instance_public_ip" {
  value = module.nexus_aws.instance_public_ip
}

output "instance_id" {
  value = module.nexus_aws.instance_id
}
