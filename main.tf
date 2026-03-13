provider "aws" {
  region = var.aws_region
}

module "nexus_aws" {
  source        = "./modules/aws"
  ami_id        = var.ami_id
  instance_type = var.instance_type
}

output "instance_public_ip" {
  value = module.nexus_aws.instance_public_ip
}
