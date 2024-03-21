data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
  depends_on = [var.eks_addon_version]
}
data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
  depends_on = [var.eks_addon_version]
}
data "aws_iam_openid_connect_provider" "oidc_provider" {
  url = data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer
  depends_on = [var.eks_addon_version]
}


provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", var.cluster_name]
    }
  }
}

module "eks_blueprints_kubernetes_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"

  cluster_name             = var.cluster_name
  cluster_version          = var.cluster_version
  cluster_endpoint         = var.cluster_endpoint
  oidc_provider_arn        = data.aws_iam_openid_connect_provider.oidc_provider.arn

  enable_aws_load_balancer_controller  = true

  depends_on = [var.eks_addon_version]
}








