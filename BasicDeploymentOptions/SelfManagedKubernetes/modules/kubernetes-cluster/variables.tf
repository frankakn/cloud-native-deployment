variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  type = string
}

variable "ssk_key_pair_name" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "The vpc id"
}

variable "my_public_ip_cidr" {
  type        = string
  description = "My public ip CIDR"
}

variable "vpc_private_subnets" {
  type        = list(any)
  description = "The private vpc subnets ids"
}

variable "vpc_public_subnets" {
  type        = list(any)
  description = "The public vpc subnets ids"
}

variable "vpc_subnet_cidr" {
  type        = string
  description = "VPC subnet CIDR"
}

variable "common_prefix" {
  type        = string
  description = "A prefix used to make cluster resources unique"
  default     = "k8s"
}

variable "ec2_associate_public_ip_address" {
  type    = bool
  default = false
}

## eu-west-1
# Ubuntu 22.04
# ami-0cffefff2d52e0a23

# Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
# ami-006be9ab6a140de6e

variable "ami" {
  type    = string
  default = "ami-024ebc7de0fc64e44"
}

variable "default_instance_type" {
  type        = string
  default     = "t3.small"
  description = "Instance type to be used"
}

variable "instance_types" {
  description = "List of instance types to use"
  type        = map(string)
  default = {
    asg_instance_type_1 = "t3.medium"
    asg_instance_type_2 = "t3a.medium"
    asg_instance_type_3 = "c5a.large"
    asg_instance_type_4 = "c6a.large"
  }
}

variable "k8s_version" {
  type    = string
  default = "1.29.6"
  description = "https://github.com/kubernetes/kubernetes/releases"
}

variable "k8s_pod_subnet" {
  type    = string
  default = "10.244.0.0/16"
}

variable "k8s_service_subnet" {
  type    = string
  default = "10.96.0.0/12"
}

variable "k8s_dns_domain" {
  type    = string
  default = "cluster.local"
}

variable "kube_api_port" {
  type        = number
  default     = 6443
  description = "Kubeapi Port"
}

variable "k8s_server_desired_capacity" {
  type        = number
  default     = 3
  description = "k8s server ASG desired capacity"
}

variable "k8s_server_min_capacity" {
  type        = number
  default     = 3
  description = "k8s server ASG min capacity"
}

variable "k8s_server_max_capacity" {
  type        = number
  default     = 4
  description = "k8s server ASG max capacity"
}

variable "k8s_worker_desired_capacity" {
  type        = number
  default     = 3
  description = "k8s server ASG desired capacity"
}

variable "k8s_worker_min_capacity" {
  type        = number
  default     = 3
  description = "k8s server ASG min capacity"
}

variable "k8s_worker_max_capacity" {
  type        = number
  default     = 4
  description = "k8s server ASG max capacity"
}

variable "cluster_name" {
  type        = string
  default     = "k8s-cluster"
  description = "Cluster name"
}

variable "install_nginx_ingress" {
  type        = bool
  default     = false
  description = "Create external LB true/false"
}

variable "nginx_ingress_release" {
  type    = string
  default = "v1.8.1"
  description = "https://github.com/kubernetes/ingress-nginx"
}

variable "install_certmanager" {
  type    = bool
  default = false
}

variable "certmanager_release" {
  type    = string
  default = "v1.12.2"
  description = "https://github.com/cert-manager/cert-manager"
}

variable "certmanager_email_address" {
  type    = string
  default = "changeme@example.com"
}

variable "create_extlb" {
  type        = bool
  default     = false
  description = "Create external LB true/false"
}

variable "efs_persistent_storage" {
  type    = bool
  default = false
}

variable "efs_csi_driver_release" {
  type    = string
  default = "v2.0.4"
  description = "https://github.com/kubernetes-sigs/aws-efs-csi-driver/releases"
}

variable "extlb_listener_http_port" {
  type    = number
  default = 30080
}

variable "extlb_listener_https_port" {
  type    = number
  default = 30443
}

variable "extlb_http_port" {
  type    = number
  default = 80
}

variable "extlb_https_port" {
  type    = number
  default = 443
}

variable "default_secret_placeholder" {
  type    = string
  default = "DEFAULTPLACEHOLDER"
}

variable "expose_kubeapi" {
  type    = bool
  default = false
}

variable "expose_kubeapi_locally" {
  type    = bool
  default = false
}

variable "install_node_termination_handler" {
  type    = bool
  default = true
}

variable "node_termination_handler_release" {
  type    = string
  default = "v1.22.0"
  description = "https://github.com/aws/aws-node-termination-handler/releases"
}