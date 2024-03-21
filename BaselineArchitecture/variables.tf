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