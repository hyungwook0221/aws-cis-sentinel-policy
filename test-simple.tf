# Simple test configuration for Sentinel policy testing

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# VPC
resource "aws_vpc" "test" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "test-vpc"
  }
}

# Security Group with SSH access (should trigger policy)
resource "aws_security_group" "test" {
  name_prefix = "test-sg"
  vpc_id      = aws_vpc.test.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # This should trigger the SSH restriction policy
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # This should trigger the RDP restriction policy
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "test-security-group"
  }
}

# S3 bucket without SSL requirement (should trigger policy)
resource "aws_s3_bucket" "test" {
  bucket = "test-bucket-sentinel-${random_string.suffix.result}"

  tags = {
    Name = "test-bucket"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# EBS volume without encryption (should trigger policy)
resource "aws_ebs_volume" "test" {
  availability_zone = "us-west-2a"
  size              = 10
  encrypted         = false  # This should trigger the EBS encryption policy

  tags = {
    Name = "test-ebs-volume"
  }
}
