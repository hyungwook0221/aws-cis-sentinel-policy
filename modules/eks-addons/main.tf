# EKS Addons Module for Well-Architected Framework

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9"
    }
  }
}

# Data sources
data "aws_region" "current" {}

# EKS Addons
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = var.cluster_name
  addon_name               = "vpc-cni"
  addon_version            = "v1.18.1-eksbuild.3"
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.vpc_cni.arn

  tags = var.tags
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = var.cluster_name
  addon_name        = "coredns"
  addon_version     = "v1.11.3-eksbuild.1"
  resolve_conflicts = "OVERWRITE"

  depends_on = [aws_eks_addon.vpc_cni]
  tags       = var.tags
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = var.cluster_name
  addon_name        = "kube-proxy"
  addon_version     = "v1.31.0-eksbuild.5"
  resolve_conflicts = "OVERWRITE"

  tags = var.tags
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.35.0-eksbuild.1"
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  tags = var.tags
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name      = var.cluster_name
  addon_name        = "eks-pod-identity-agent"
  addon_version     = "v1.3.4-eksbuild.1"
  resolve_conflicts = "OVERWRITE"

  tags = var.tags
}

# IAM Role for VPC CNI
resource "aws_iam_role" "vpc_cni" {
  name = "${var.cluster_name}-vpc-cni-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(var.cluster_endpoint, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-node"
            "${replace(var.cluster_endpoint, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni.name
}

# IAM Role for EBS CSI Driver
resource "aws_iam_role" "ebs_csi" {
  name = "${var.cluster_name}-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(var.cluster_endpoint, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(var.cluster_endpoint, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi.name
}