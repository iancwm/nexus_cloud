# AWS Infrastructure Module: Nexus-Cloud

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

provider "aws" {
  region = var.aws_region
}

# --- Variables ---
locals {
  resource_prefix = "nexus-${var.user_id}-${var.workspace_name}"
}

# --- IAM: Identity & Roles ---

resource "aws_iam_role" "nexus_role" {
  name = "${local.resource_prefix}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.nexus_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "nexus_policy" {
  name = "${local.resource_prefix}-policy"
  role = aws_iam_role.nexus_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = "*" 
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::nexus-identity-*",
          "arn:aws:s3:::nexus-identity-*/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "nexus_profile" {
  name = "${local.resource_prefix}-profile"
  role = aws_iam_role.nexus_role.name
}

# --- Networking ---

resource "aws_vpc" "nexus_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${local.resource_prefix}-vpc" }
}

resource "aws_subnet" "nexus_subnet" {
  vpc_id                  = aws_vpc.nexus_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "${local.resource_prefix}-subnet" }
}

resource "aws_internet_gateway" "nexus_igw" {
  vpc_id = aws_vpc.nexus_vpc.id
}

resource "aws_route_table" "nexus_rt" {
  vpc_id = aws_vpc.nexus_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nexus_igw.id
  }
}

resource "aws_route_table_association" "nexus_rta" {
  subnet_id      = aws_subnet.nexus_subnet.id
  route_table_id = aws_route_table.nexus_rt.id
}

resource "aws_security_group" "nexus_sg" {
  name        = "${local.resource_prefix}-sg"
  vpc_id      = aws_vpc.nexus_vpc.id
  description = "Zero-port ingress security group"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- S3: Identity Snapshots ---

resource "aws_s3_bucket" "nexus_identity" {
  bucket_prefix = "nexus-identity-"
  force_destroy = false 
}

resource "aws_s3_bucket_public_access_block" "nexus_identity_block" {
  bucket = aws_s3_bucket.nexus_identity.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- AMI Lookup ---

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# --- Coder Parameters ---

data "coder_parameter" "instance_type" {
  name         = "instance_type"
  display_name = "Instance Type"
  description  = "The EC2 instance type to use"
  default      = "t3.large"
  icon         = "/icon/aws.svg"
  mutable      = true
}

data "coder_parameter" "ebs_size" {
  name         = "ebs_size"
  display_name = "Persistent Disk Size (GB)"
  description  = "Size of the secondary persistent EBS volume"
  default      = "20"
  type         = "number"
  icon         = "/icon/aws.svg"
  mutable      = true
}

# --- Coder Agent ---

resource "coder_agent" "main" {
  arch           = "amd64"
  os             = "linux"
  
  # Pipe logs to Coder UI by running setup here
  startup_script = <<-EOT
    #!/bin/bash
    set -e
    echo "--- Coder Agent Connected: Starting Unified Setup ---"
    
    # Wait for files written by user_data
    while [ ! -f /home/ubuntu/setup.sh ]; do
      echo "Waiting for setup scripts..."
      sleep 2
    done

    chmod +x /home/ubuntu/setup.sh /home/ubuntu/sync_identity.sh
    
    echo "Executing Provisioner (This may take several minutes)..."
    sudo -E /home/ubuntu/setup.sh
    
    echo "--- Setup Complete: Workspace Ready ---"
  EOT

  # High timeout for full toolchain install
  startup_script_timeout = 1800

  metadata {
    display_name = "Public IP"
    key          = "public_ip"
    script       = "curl -s -H \"X-aws-ec2-metadata-token: $TOKEN\" http://169.254.169.254/latest/meta-data/public-ipv4"
    interval     = 60
    timeout      = 5
  }
}

# --- SSH Keys ---

resource "aws_key_pair" "nexus_key" {
  count      = var.ssh_public_key != "" ? 1 : 0
  key_name   = "${local.resource_prefix}-key"
  public_key = var.ssh_public_key
}

# --- Compute: EC2 & Persistent Disk ---

resource "aws_instance" "nexus_workspace" {
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type = coalesce(data.coder_parameter.instance_type.value, var.instance_type)
  subnet_id     = aws_subnet.nexus_subnet.id
  vpc_security_group_ids = [aws_security_group.nexus_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.nexus_profile.name
  key_name               = var.ssh_public_key != "" ? aws_key_pair.nexus_key[0].key_name : null

  tags = { 
    Name = "${local.resource_prefix}-workspace" 
    Coder_User = var.user_id
    Coder_Workspace = var.workspace_name
  }

  volume_tags = {
    Name = "${local.resource_prefix}-root-volume"
    Coder_Workspace = var.workspace_name
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = <<-EOT
    #!/bin/bash
    set -e
    
    # 1. Place scripts on disk immediately (Safe & Reliable)
    echo "${base64encode(file("${path.module}/../../setup.sh"))}" | base64 -d > /home/ubuntu/setup.sh
    echo "${base64encode(file("${path.module}/../../sync_identity.sh"))}" | base64 -d > /home/ubuntu/sync_identity.sh
    echo "${base64encode(file("${path.module}/../../nexus-sync.service"))}" | base64 -d > /home/ubuntu/nexus-sync.service
    chown -R ubuntu:ubuntu /home/ubuntu/

    # 2. Start Coder Agent
    export CODER_AGENT_TOKEN="${coder_agent.main.token}"
    ${coder_agent.main.init_script}
  EOT
}

resource "aws_ebs_volume" "persistent_config" {
  availability_zone = aws_instance.nexus_workspace.availability_zone
  size              = data.coder_parameter.ebs_size.value
  tags = { Name = "${local.resource_prefix}-persistent-config" }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.persistent_config.id
  instance_id = aws_instance.nexus_workspace.id
}
