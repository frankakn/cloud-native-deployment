variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "An identifier for the current environment to separate deployments"
  type        = string
  default     = "staging"
}

variable "my_public_ip_cidr" {
  description = "A CIDR range to allow access to the bastion host via SSH"
  type        = string
  default     = "141.13.163.0/24" #<SET A CIDR RANGE HERE>"
}

variable "vpc_cidr_block" {
  description = "A CIDR range to allow access between hosts of the private subnet"
  type        = string
  default     = "172.68.0.0/16"
}

variable "ssk_key_pair_name" {
  description = "The name of an existing SSH key pair which is used to access the bastion host"
  type        = string
  default     = "aws-bastion" #<SET YOUR SSH KEY NAME HERE>"
}
