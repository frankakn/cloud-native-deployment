provider "aws" {
  region = var.region
}

module "private-vpc" {
  region            = var.region
  my_public_ip_cidr = var.my_public_ip_cidr
  vpc_cidr_block    = var.vpc_cidr_block
  environment       = var.environment
  source            = ".././modules/private-vpc"
}

output "private_subnets_ids" {
  value = module.private-vpc.private_subnet_ids
}

output "public_subnets_ids" {
  value = module.private-vpc.public_subnet_ids
}

output "security_group_id" {
  value = module.private-vpc.security_group_id
}

output "vpc_id" {
  value = module.private-vpc.vpc_id
}

module "bastion-host" {
  ssk_key_pair_name  = var.ssk_key_pair_name
  environment        = var.environment
  subnet_id          = module.private-vpc.public_subnet_ids[0]
  security_group_ids = [module.private-vpc.security_group_id]
  ssh_keys_path      = ["~/.ssh/${var.ssk_key_pair_name}.pub"]
  source             = ".././modules/bastion-host"
}

output "bastion_host_ip" {
  value = module.bastion-host.bastion_ip
}

module "k8s-cluster" {
  ssk_key_pair_name         = var.ssk_key_pair_name
  region                    = var.region
  environment               = var.environment
  vpc_id                    = module.private-vpc.vpc_id
  vpc_private_subnets       = module.private-vpc.private_subnet_ids
  vpc_public_subnets        = module.private-vpc.public_subnet_ids
  vpc_subnet_cidr           = var.vpc_cidr_block
  my_public_ip_cidr         = var.my_public_ip_cidr
  create_extlb              = true
  install_nginx_ingress     = true
  efs_persistent_storage    = true
  expose_kubeapi            = false
  expose_kubeapi_locally    = true
  install_certmanager       = true
  certmanager_email_address = var.certmanager_email_address
  source                    = ".././modules/kubernetes-cluster"
}

output "k8s_dns_name" {
  value = module.k8s-cluster.k8s_dns_name
}

output "k8s_server_private_ips" {
  value = module.k8s-cluster.k8s_server_private_ips
}

output "k8s_workers_private_ips" {
  value = module.k8s-cluster.k8s_workers_private_ips
}

