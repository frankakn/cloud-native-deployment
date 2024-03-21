provider "aws" {
  region = var.region
}

locals {
  cluster_name = var.cluster_name
}
locals {
  cluster_version = "1.27"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "eks-managed-vpc"
  tags = {
    Name = "eks-managed-vpc"
  }

  cidr = "10.0.0.0/16"
  azs  = ["us-east-2a", "us-east-2b", "us-east-2c"]

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]


  enable_nat_gateway   = true # instances in private subnet can connect to services outside vpc
  single_nat_gateway   = false # creates one nat gateway per availability zone, instead of a single nat geteway
  enable_dns_hostnames = true
  enable_dns_support   = true 

  public_subnet_tags = {
    Name = "public"
    "kubernetes.io/cluster/${var.cluster_name}"   = "owned"
    "kubernetes.io/role/elb"                      = 1 # allows creation of load balancer
  }

  private_subnet_tags = {
    Name = "private"
    "kubernetes.io/cluster/${var.cluster_name}"   = "owned"
    "kubernetes.io/role/internal-elb"             = 1 # allows creation of internal loda balancer
    "karpenter.sh/discovery"                      = var.cluster_name
  }

}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = var.cluster_name
  cluster_version = local.cluster_version
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true 
  cluster_endpoint_private_access = false 
  enable_irsa = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64" # Type of Amazon Machine Image (AMI) associated with the EKS Node Group. 

  }

  eks_managed_node_groups = {
    one = {
      name = var.node_group_1_name

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 5
      desired_size = 2
      
    }

    two = {
      name = var.node_group_2_name

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 5
      desired_size = 1
    }
  }
   node_security_group_tags  = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}


# Elastic Block Store (EBS) Container Storage Interface (CSI) Driver
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy" #This CSI driver enables container orchestrators (such as Kubernetes) to manage the lifecycle of Amazon EBS volumes
} 

# creates an IAM role with web identity provider (OIDC) trust and maps the previously retrieved IAM policy (AmazonEBSCSIDriverPolicy) to that role.
module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "4.7.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

# provides the Amazon EBS CSI driver add-on in the EKS cluster.
resource "aws_eks_addon" "ebs-csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.20.0-eksbuild.1"
  service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
  tags = {
    "eks_addon" = "ebs-csi"
    "terraform" = "true"
  }
}