provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

output "eks_vpc_id" {
  value = data.aws_eks_cluster.eks.vpc_config[0].vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_eks_cluster.eks.vpc_config[0].vpc_id]
  }

  tags = {
    "Name" = "private"
  }
}

resource "aws_efs_file_system" "filesystem" {
  creation_token = "filesystem"
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "eks-filesystem"
  }
}

resource "aws_security_group" "filesystem" {
  name        = "efs_security_group"
  description = "Security group for EFS"
  vpc_id      = data.aws_eks_cluster.eks.vpc_config[0].vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_efs_mount_target" "filesystem" {
  count                = length(data.aws_subnets.private.ids)
  file_system_id       = aws_efs_file_system.filesystem.id
  subnet_id            = data.aws_subnets.private.ids[count.index]
  security_groups      = [aws_security_group.filesystem.id]
}