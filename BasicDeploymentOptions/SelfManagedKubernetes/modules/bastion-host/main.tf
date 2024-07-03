data "template_cloudinit_config" "bastion_host" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/files/cloud-config-base.yaml", {})
  }


  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/files/setup_bastion.sh", { ssh_keys = local.ssh_keys, bastion_user = var.bastion_user, bastion_group = var.bastion_group })
  }
  
}

locals {
  tags = {
    "environment" = "${var.environment}"
  }

  ssh_keys = [for ssh_key in var.ssh_keys_path : file(ssh_key)]
}

resource "aws_instance" "bastion_host" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.ssk_key_pair_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids

  user_data = data.template_cloudinit_config.bastion_host.rendered

  tags = merge(
    local.tags,
    {
      Name = "bation-host-${var.environment}"
    }
  )

}

