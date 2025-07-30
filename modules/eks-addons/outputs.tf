# EKS Addons Module Outputs

output "vpc_cni_addon" {
  description = "VPC CNI addon details"
  value       = aws_eks_addon.vpc_cni
}

output "coredns_addon" {
  description = "CoreDNS addon details"
  value       = aws_eks_addon.coredns
}

output "kube_proxy_addon" {
  description = "Kube-proxy addon details"
  value       = aws_eks_addon.kube_proxy
}

output "ebs_csi_addon" {
  description = "EBS CSI driver addon details"
  value       = aws_eks_addon.ebs_csi_driver
}

output "pod_identity_agent_addon" {
  description = "Pod Identity Agent addon details"
  value       = aws_eks_addon.pod_identity_agent
}