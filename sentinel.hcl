policy "ec2-security-group-ingress-traffic-restriction-port-22" {
  source = "./sentinel/policies/ec2-security-group-ingress-traffic-restriction-port-22.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "ec2-security-group-ingress-traffic-restriction-port-3389" {
  source = "./sentinel/policies/ec2-security-group-ingress-traffic-restriction-port-3389.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "ec2-ebs-encryption-enabled" {
  source = "./sentinel/policies/ec2-ebs-encryption-enabled.sentinel"
  enforcement_level = "advisory"
}

policy "s3-require-ssl" {
  source = "./sentinel/policies/s3-require-ssl.sentinel"
  enforcement_level = "advisory"
}

policy "s3-block-public-access-bucket-level" {
  source = "./sentinel/policies/s3-block-public-access-bucket-level.sentinel"
  enforcement_level = "advisory"
}
