terraform {
  cloud {
    organization = "hyungwook-test-org"  # 실제 HCP Terraform organization 이름으로 변경 필요
    
    workspaces {
      name = "cis-sentinel-test"
    }
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC 생성
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "cis-test-vpc"
  }
}

# 인터넷 게이트웨이
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "cis-test-igw"
  }
}

# 퍼블릭 서브넷
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "cis-test-public-subnet"
  }
}

# 라우팅 테이블
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "cis-test-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# CIS 정책 위반을 위한 보안 그룹 (SSH/RDP 포트 개방)
resource "aws_security_group" "vulnerable_sg" {
  name_description = "CIS test - vulnerable security group"
  vpc_id          = aws_vpc.main.id

  # SSH 포트를 모든 IP에 개방 (CIS 위반)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # RDP 포트를 모든 IP에 개방 (CIS 위반)
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cis-test-vulnerable-sg"
  }
}

# 암호화되지 않은 EBS 볼륨 (CIS 위반)
resource "aws_ebs_volume" "unencrypted" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 10
  encrypted         = false  # CIS 위반

  tags = {
    Name = "cis-test-unencrypted-volume"
  }
}

# S3 버킷 (보안 설정 누락으로 CIS 위반)
resource "aws_s3_bucket" "test_bucket" {
  bucket = "cis-test-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "cis-test-bucket"
  }
}

# S3 버킷 퍼블릭 액세스 차단 설정 누락 (CIS 위반)
# aws_s3_bucket_public_access_block 리소스가 없음

# CloudTrail 설정 누락 (CIS 위반)
# aws_cloudtrail 리소스가 없음

# 랜덤 ID 생성
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 데이터 소스
data "aws_availability_zones" "available" {
  state = "available"
}
