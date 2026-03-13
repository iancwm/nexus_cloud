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

# --- IAM: Identity & Roles ---

resource "aws_iam_role" "nexus_role" {
  name = "nexus-cloud-instance-role"

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

resource "aws_iam_role_policy" "nexus_policy" {
  name = "nexus-cloud-policy"
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
        Resource = "*" # Scoped to nexus-cloud secrets in production
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::nexus-cloud-identity-*",
          "arn:aws:s3:::nexus-cloud-identity-*/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "nexus_profile" {
  name = "nexus-cloud-profile"
  role = aws_iam_role.nexus_role.name
}

# --- Secrets Manager: AI Keys ---

resource "aws_secretsmanager_secret" "ai_keys" {
  name        = "nexus-cloud/ai-api-keys"
  description = "AI API keys for Nexus-Cloud Workspace (Anthropic, OpenAI, etc.)"
  recovery_window_in_days = 0 # For development convenience; set higher in production
}

# --- Networking ---

resource "aws_vpc" "nexus_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "nexus-vpc" }
}

resource "aws_subnet" "nexus_subnet" {
  vpc_id                  = aws_vpc.nexus_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "nexus-subnet" }
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
  name        = "nexus-cloud-sg"
  vpc_id      = aws_vpc.nexus_vpc.id
  description = "Allow SSH and outbound"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Scoped to user IP in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- S3: Identity Snapshots ---

resource "aws_s3_bucket" "nexus_identity" {
  bucket_prefix = "nexus-cloud-identity-"
  force_destroy = false # Protect identity data
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

# --- Coder Agent ---

resource "coder_agent" "main" {
  arch           = "amd64"
  os             = "linux"
  startup_script = <<-EOT
    #!/bin/bash
    # Pull scripts from metadata or a known source
    # For a template, we assume setup.sh is in the repo
    # Coder will execute this on start
    echo "Starting Nexus-Cloud Coder Agent Setup..."
    if [ ! -f ~/setup.sh ]; then
      # Optional: Logic to pull setup.sh if not baked into AMI
      echo "Waiting for setup.sh..."
    fi
    chmod +x ~/setup.sh
    ~/setup.sh
  EOT
}
# --- SSH Keys ---

resource "aws_key_pair" "nexus_key" {
  count      = var.ssh_public_key != "" ? 1 : 0
  key_name   = "nexus-key-${var.user_id}"
  public_key = var.ssh_public_key
}

# --- Compute: EC2 & Persistent Disk ---

resource "aws_instance" "nexus_workspace" {
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.nexus_subnet.id
  vpc_security_group_ids = [aws_security_group.nexus_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.nexus_profile.name
  key_name               = var.ssh_public_key != "" ? aws_key_pair.nexus_key[0].key_name : null

  tags = { 
    Name = "nexus-workspace" 
    Coder_User = var.user_id
  }

  user_data = coder_agent.main.startup_script
}

resource "aws_ebs_volume" "persistent_config" {
  availability_zone = aws_instance.nexus_workspace.availability_zone
  size              = 20
  tags = { Name = "nexus-persistent-config" }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.persistent_config.id
  instance_id = aws_instance.nexus_workspace.id
}
