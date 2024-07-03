variable "ssk_key_pair_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ami" {
  type    = string
  default = "ami-033fabdd332044f06"
}

variable "bastion_user" {
  type    = string
  default = "bastion"
}

variable "bastion_group" {
  type    = string
  default = "bastion"
}

variable "ssh_keys_path" {
  type    = list(any)
  default = ["~/.ssh/id_rsa.pub"]
}
