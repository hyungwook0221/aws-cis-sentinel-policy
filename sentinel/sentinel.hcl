policy "s3-require-ssl" {
  source = "https://registry.terraform.io/v2policies/hashicorp/CIS-Policy-Set-for-AWS-Terraform/1.0.1/policy/s3-require-ssl.sentinel?checksum=sha256:df5bb5db59c8d4300cd3df6394d61bc0d2a9ba8557fb35308b1776ad592498a5"
  enforcement_level = "advisory"
}

policy "s3-block-public-access-bucket-level" {
  source = "https://registry.terraform.io/v2policies/hashicorp/CIS-Policy-Set-for-AWS-Terraform/1.0.1/policy/s3-block-public-access-bucket-level.sentinel?checksum=sha256:38cb17fd70b9e87bbc3283cc720458965dca75fc6074c159d301d6f901443ae1"
  enforcement_level = "hard-mandatory"
}

policy "s3-block-public-access-account-level" {
  source = "https://registry.terraform.io/v2policies/hashicorp/CIS-Policy-Set-for-AWS-Terraform/1.0.1/policy/s3-block-public-access-account-level.sentinel?checksum=sha256:fe9b5590e1f1c80aea63ad14c278f65c2d9a090d50e42f808f7480df229e84b6"
  enforcement_level = "hard-mandatory"
}

policy "kms-key-rotation-enabled" {
  source = "https://registry.terraform.io/v2policies/hashicorp/CIS-Policy-Set-for-AWS-Terraform/1.0.1/policy/kms-key-rotation-enabled.sentinel?checksum=sha256:61adb15b95eaaf4eec58988262f370837ba9602f372196e33488705bdd5b1d11"
  enforcement_level = "advisory"
}

policy "cloudtrail-server-side-encryption-enabled" {
  source = "https://registry.terraform.io/v2policies/hashicorp/CIS-Policy-Set-for-AWS-Terraform/1.0.1/policy/cloudtrail-server-side-encryption-enabled.sentinel?checksum=sha256:5f99126f0c9d083f0d9268c452e619f27494dfb3a64bcf20dfbaf8825c939576"
  enforcement_level = "advisory"
}

policy "cloudtrail-cloudwatch-logs-group-arn-present" {
  source = "https://registry.terraform.io/v2policies/hashicorp/CIS-Policy-Set-for-AWS-Terraform/1.0.1/policy/cloudtrail-cloudwatch-logs-group-arn-present.sentinel?checksum=sha256:889632628547ffd5139c557b3f8403f50f821c36220ada5898656a8c345ed96f"
  enforcement_level = "advisory"
}

policy "cloudtrail-log-file-validation-enabled" {
  source = "https://registry.terraform.io/v2policies/hashicorp/CIS-Policy-Set-for-AWS-Terraform/1.0.1/policy/cloudtrail-log-file-validation-enabled.sentinel?checksum=sha256:41811c239101d6d98a80a6529feb9c47e2e0126a5391a666b80bdce3931d242c"
  enforcement_level = "advisory"
}

policy "ec2-security-group-ingress-traffic-restriction-port-22" {
  source = "https://registry.terraform.io/v2policies/hashicorp/CIS-Policy-Set-for-AWS-Terraform/1.0.1/policy/ec2-security-group-ingress-traffic-restriction-port-22.sentinel?checksum=sha256:dfe1e79a65e5fcd06c23a635a844b5a2046f05eb4d77f78620fa73197b54c08b"
  enforcement_level = "hard-mandatory"
}

policy "ec2-security-group-ingress-traffic-restriction-port-3389" {
  source = "https://registry.terraform.io/v2policies/hashicorp/CIS-Policy-Set-for-AWS-Terraform/1.0.1/policy/ec2-security-group-ingress-traffic-restriction-port-3389.sentinel?checksum=sha256:dfe1e79a65e5fcd06c23a635a844b5a2046f05eb4d77f78620fa73197b54c08b"
  enforcement_level = "hard-mandatory"
}

policy "ec2-vpc-default-security-group-no-traffic" {
  source = "https://registry.terraform.io/v2policies/hashicorp/CIS-Policy-Set-for-AWS-Terraform/1.0.1/policy/ec2-vpc-default-security-group-no-traffic.sentinel?checksum=sha256:f2d13e7056aaa5eb708c2944a4fed736da2746c5ac17b2fc7f1c870ba8617cc9"
  enforcement_level = "advisory"
}

policy "vpc-flow-logging-enabled" {
  source = "https://registry.terraform.io/v2policies/hashicorp/CIS-Policy-Set-for-AWS-Terraform/1.0.1/policy/vpc-flow-logging-enabled.sentinel?checksum=sha256:6613a4845dd3d8e4dd62414ee3e69f7c6fad1e8d7132dd5617dc7dc2280cfa83"
  enforcement_level = "advisory"
}

policy "ec2-ebs-encryption-enabled" {
  source = "https://registry.terraform.io/v2policies/hashicorp/CIS-Policy-Set-for-AWS-Terraform/1.0.1/policy/ec2-ebs-encryption-enabled.sentinel?checksum=sha256:ad0d6f7f068396d0cadd55dbb665b0379d232f4122ab62e674f263b2eb762dba"
  enforcement_level = "advisory"
}

policy "ec2-metadata-imdsv2-required" {
  source = "https://registry.terraform.io/v2policies/hashicorp/CIS-Policy-Set-for-AWS-Terraform/1.0.1/policy/ec2-metadata-imdsv2-required.sentinel?checksum=sha256:fdb048dc53e75ad6623608e4d36562a548b91528f5db659e3a98add267518617"
  enforcement_level = "advisory"
}

module "tfplan-functions" {
  source = "https://registry.terraform.io/v2policies/hashicorp/CIS-Policy-Set-for-AWS-Terraform/1.0.1/policy-module/tfplan-functions.sentinel?checksum=sha256:e7f04948ec53d7c01ff26829c1ef7079fb072ed5074483f94dd3d00ae5bb67b3"
}

module "report" {
  source = "https://registry.terraform.io/v2policies/hashicorp/CIS-Policy-Set-for-AWS-Terraform/1.0.1/policy-module/report.sentinel?checksum=sha256:1f414f31c2d6f7e4c3f61b2bc7c25079ea9d5dd985d865c01ce9470152fa696d"
}

module "tfconfig-functions" {
  source = "https://registry.terraform.io/v2policies/hashicorp/CIS-Policy-Set-for-AWS-Terraform/1.0.1/policy-module/tfconfig-functions.sentinel?checksum=sha256:ee1c5baf3c2f6b032ea348ce38f0a93d54b6e5337bade1386fffb185e2599b5b"
}

module "tfresources" {
  source = "https://registry.terraform.io/v2policies/hashicorp/CIS-Policy-Set-for-AWS-Terraform/1.0.1/policy-module/tfresources.sentinel?checksum=sha256:5b91f0689dd6d68d17bed2612cd72127a6dcfcedee0e2bb69a617ded71ad0168"
}
