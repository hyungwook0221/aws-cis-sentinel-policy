# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

import "module" "report" {
  source = "./sentinel/modules/report/report.sentinel"
}

import "module" "tfresources" {
  source = "./sentinel/modules/tfresources/tfresources.sentinel"
}

import "module" "tfplan-functions" {
  source = "./sentinel/modules/tfplan-functions/tfplan-functions.sentinel"
}

import "module" "tfconfig-functions" {
  source = "./sentinel/modules/tfconfig-functions/tfconfig-functions.sentinel"
}

policy "ec2-security-group-ingress-traffic-restriction-port" {
  source = "./sentinel/policies/ec2/ec2-security-group-ingress-traffic-restriction-port.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "ec2-ebs-encryption-enabled" {
  source = "./sentinel/policies/ec2/ec2-ebs-encryption-enabled.sentinel"
  enforcement_level = "advisory"
}

policy "s3-require-ssl" {
  source = "./sentinel/policies/s3/s3-require-ssl.sentinel"
  enforcement_level = "advisory"
}

policy "s3-block-public-access-bucket-level" {
  source = "./sentinel/policies/s3/s3-block-public-access-bucket-level.sentinel"
  enforcement_level = "advisory"
}
