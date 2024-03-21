variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "cluster_name" {
  type        = string
  default = "eks-cluster"
  description = "The name of the cluster"
}

variable "node_group_1_name" {
  type        = string
  default = "node-group-1"
  description = "The name of the first node group"
}


variable "node_group_2_name" {
  type        = string
  default = "node-group-2"
  description = "The name of the second node group"
}

