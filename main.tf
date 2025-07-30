# AWS Well-Architected EKS Cluster Configuration

terraform {
  required_version = ">= 1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

# KMS Key for EKS cluster encryption
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-eks-encryption-key"
  })
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Enable VPC Flow Logs for security monitoring
  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = var.tags
}

# EKS Module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Cluster endpoint configuration - Well-Architected security practice
  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  # Enable cluster logging for all log types - Well-Architected observability
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Cluster encryption configuration
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    for name, config in var.node_groups : name => {
      instance_types = config.instance_types
      capacity_type  = config.capacity_type

      min_size     = config.min_size
      max_size     = config.max_size
      desired_size = config.desired_size

      # Use latest EKS optimized AMI
      ami_type = "AL2023_x86_64_STANDARD"

      # Enable IMDSv2 for security
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      # EBS encryption
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      # Security group rules
      create_security_group = true
      security_group_rules = {
        ingress_cluster_443 = {
          description                   = "Cluster API to node groups"
          protocol                      = "tcp"
          from_port                     = 443
          to_port                       = 443
          type                          = "ingress"
          source_cluster_security_group = true
        }
        ingress_cluster_kubelet = {
          description                   = "Cluster API to node kubelets"
          protocol                      = "tcp"
          from_port                     = 10250
          to_port                       = 10250
          type                          = "ingress"
          source_cluster_security_group = true
        }
        ingress_self_coredns_tcp = {
          description = "Node to node CoreDNS"
          protocol    = "tcp"
          from_port   = 53
          to_port     = 53
          type        = "ingress"
          self        = true
        }
        ingress_self_coredns_udp = {
          description = "Node to node CoreDNS UDP"
          protocol    = "udp"
          from_port   = 53
          to_port     = 53
          type        = "ingress"
          self        = true
        }
        egress_all = {
          description = "Node all egress"
          protocol    = "-1"
          from_port   = 0
          to_port     = 0
          type        = "egress"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }

      tags = merge(var.tags, {
        Name = "${var.cluster_name}-${name}-node-group"
      })
    }
  }

  # Cluster access entry
  access_entries = {
    cluster_creator = {
      principal_arn = data.aws_caller_identity.current.arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = var.tags
}
# E
KS Addons for Well-Architected Framework
module "eks_addons" {
  source = "./modules/eks-addons"

  cluster_name                = module.eks.cluster_name
  cluster_endpoint            = module.eks.cluster_endpoint
  cluster_version             = module.eks.cluster_version
  oidc_provider_arn          = module.eks.oidc_provider_arn
  node_security_group_id     = module.eks.node_security_group_id
  
  tags = var.tags

  depends_on = [module.eks]
}

# CloudWatch Log Groups for EKS
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.eks.arn

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cluster-logs"
  })
}

# Security Group for additional rules
resource "aws_security_group_rule" "cluster_ingress_workstation_https" {
  description       = "Allow workstation to communicate with the cluster API Server"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [module.vpc.vpc_cidr_block]
  security_group_id = module.eks.cluster_security_group_id
}

# IAM role for EKS service account (IRSA)
resource "aws_iam_role" "eks_service_account" {
  name = "${var.cluster_name}-service-account-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}