output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "eks_managed_node_groups_autoscaling_group_names" {
  description = "List of the autoscaling group names created by EKS managed node groups"
  value       = module.eks.eks_managed_node_groups_autoscaling_group_names
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       =  module.eks.cluster_arn
}

output "cluster_id" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       =  module.eks.cluster_id
}

output "eks_addon_version" {
  description = "The eks addon version"
  value = aws_eks_addon.ebs-csi.addon_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = try(module.eks.this[0].identity[0].oidc[0].issuer, null)
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       =  module.eks.cluster_version
}

output "cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = try(module.eks.this[0].platform_version, null)
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = try(module.eks.this[0].status, null)
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console"
  value       = try(module.eks.this[0].vpc_config[0].cluster_security_group_id, null)
}