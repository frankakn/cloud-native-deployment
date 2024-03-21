provider "aws" {
  region = var.region
}

module "eks-cluster-creation" {
  source = "./modules/eks-cluster-creation"
}

# Here the output variables from the outputs.tf of the eks-cluster-creation module are inserted wo the load-balancer-controller module
module "load-balancer-controller" {
  source                         = "./modules/load-balancer-controller"
  cluster_arn                    = module.eks-cluster-creation.cluster_arn
  cluster_oidc_issuer_url        = module.eks-cluster-creation.cluster_oidc_issuer_url
  cluster_endpoint               = module.eks-cluster-creation.cluster_endpoint
  cluster_certificate_authority_data = module.eks-cluster-creation.cluster_certificate_authority_data
  cluster_name    = module.eks-cluster-creation.cluster_name
  cluster_version = module.eks-cluster-creation.cluster_version
  cluster_id = module.eks-cluster-creation.cluster_id
  eks_addon_version = module.eks-cluster-creation.eks_addon_version

}

output "autoscaling_group_names" {
  value = module.eks-cluster-creation.eks_managed_node_groups_autoscaling_group_names
}
