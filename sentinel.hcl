# Sentinel Policy Configuration for AWS CIS Foundations Benchmark
# This file defines the policy set for HCP Terraform

# EC2 Security Policies
policy "aws-cis-ec2-ebs-encryption" {
    source = "./sentinel/policies/ec2/ec2-ebs-encryption-enabled.sentinel"
    enforcement_level = "hard-mandatory"
}

policy "aws-cis-ec2-imdsv2" {
    source = "./sentinel/policies/ec2/ec2-metadata-imdsv2-required.sentinel"
    enforcement_level = "hard-mandatory"
}

policy "aws-cis-ec2-security-groups" {
    source = "./sentinel/policies/ec2/ec2-security-group-ingress-traffic-restriction-port.sentinel"
    enforcement_level = "hard-mandatory"
}

policy "aws-cis-ec2-default-security-group" {
    source = "./sentinel/policies/ec2/ec2-vpc-default-security-group-no-traffic.sentinel"
    enforcement_level = "soft-mandatory"
}

# VPC Security Policies
policy "aws-cis-vpc-flow-logs" {
    source = "./sentinel/policies/vpc/vpc-flow-logging-enabled.sentinel"
    enforcement_level = "hard-mandatory"
}

# IAM Security Policies
policy "aws-cis-iam-password-length" {
    source = "./sentinel/policies/iam/iam-password-length.sentinel"
    enforcement_level = "soft-mandatory"
}

policy "aws-cis-iam-password-complexity" {
    source = "./sentinel/policies/iam/iam-password-uppercase.sentinel"
    enforcement_level = "soft-mandatory"
}

policy "aws-cis-iam-no-admin-policies" {
    source = "./sentinel/policies/iam/iam-no-admin-privileges-allowed-by-policies.sentinel"
    enforcement_level = "advisory"
}

policy "aws-cis-iam-no-user-policies" {
    source = "./sentinel/policies/iam/iam-no-policies-attached-to-users.sentinel"
    enforcement_level = "soft-mandatory"
}

# S3 Security Policies
policy "aws-cis-s3-public-access-block" {
    source = "./sentinel/policies/s3/s3-block-public-access-bucket-level.sentinel"
    enforcement_level = "hard-mandatory"
}

policy "aws-cis-s3-ssl-requests" {
    source = "./sentinel/policies/s3/s3-require-ssl.sentinel"
    enforcement_level = "hard-mandatory"
}

# KMS Security Policies
policy "aws-cis-kms-key-rotation" {
    source = "./sentinel/policies/kms/kms-key-rotation-enabled.sentinel"
    enforcement_level = "advisory"
}

# CloudTrail Security Policies
policy "aws-cis-cloudtrail-encryption" {
    source = "./sentinel/policies/cloudtrail/cloudtrail-server-side-encryption-enabled.sentinel"
    enforcement_level = "soft-mandatory"
}

policy "aws-cis-cloudtrail-log-validation" {
    source = "./sentinel/policies/cloudtrail/cloudtrail-log-file-validation-enabled.sentinel"
    enforcement_level = "soft-mandatory"
}

# EFS Security Policies
policy "aws-cis-efs-encryption" {
    source = "./sentinel/policies/efs/efs-encryption-at-rest-enabled.sentinel"
    enforcement_level = "hard-mandatory"
}

# RDS Security Policies
policy "aws-cis-rds-encryption" {
    source = "./sentinel/policies/rds/rds-encryption-at-rest-enabled.sentinel"
    enforcement_level = "hard-mandatory"
}

policy "aws-cis-rds-public-access" {
    source = "./sentinel/policies/rds/rds-public-access-disabled.sentinel"
    enforcement_level = "hard-mandatory"
}