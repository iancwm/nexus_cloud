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

provider "aws" {
  region = var.aws_region
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

import {
  to = module.nexus_aws.aws_secretsmanager_secret.ai_keys
  id = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:nexus-cloud/ai-api-keys"
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
  ssh_public_key = var.ssh_public_key
}

output "instance_public_ip" {
  value = module.nexus_aws.instance_public_ip
}
