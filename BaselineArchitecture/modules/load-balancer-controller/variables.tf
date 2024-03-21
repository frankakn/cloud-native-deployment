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

variable "cluster_version" {
  type        = string
  description = "The version of the cluster"
}

variable "cluster_id" {
  type        = string
  description = "The id of the cluster"
}

variable "eks_addon_version" {
  type        = string
  description = "The eks addon version"
}

variable "cluster_arn" {
  type        = string
  description = "The arn of the cluster"
}

variable "cluster_oidc_issuer_url" {
  type        = string
  description = "The issuer url of the cluster"
}

variable "cluster_endpoint" {
  type        = string
  description = "The endpoint of the cluster"
}

variable "cluster_certificate_authority_data" {
  type        = string
  description = "The certificate authority of the cluster"
}