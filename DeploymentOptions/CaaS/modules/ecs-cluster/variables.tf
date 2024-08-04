variable "region" {
  description = "The AWS region in which to run the cluster"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "An identifier for the current environment to separate deployments"
  type        = string
  default     = "staging"
}

variable "ecs_cluster_name" {
  description = "A name for the ECS cluster"
  type        = string
  default     = "my-ecs-cluster"
}

variable "instance_ami" {
  description = "The AWS machine image id to use for the cluster instances"
  type        = string
  default     = "ami-0a31f06d64a91614b"
}

variable "instance_type" {
  description = "The instance type to use for the cluster instances"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "The SSH Key added to AWS EC2 to access instances"
  type        = string
}

variable "vpc_id" {
  description = "The id of the vpc to use"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "TODO"
  type        = list(string)
}

variable "vpc_private_subnet_ids" {
  description = "TODO"
  type        = list(string)
}

variable "vpc_public_subnet_ids" {
  description = "TODO"
  type        = list(string)
}

