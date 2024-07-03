locals {
  k8s_tls_san_public        = var.create_extlb && var.expose_kubeapi ? aws_lb.external_lb[0].dns_name : ""
  kubeconfig_secret_name    = "${var.common_prefix}-kubeconfig/${var.cluster_name}/${var.environment}/v1"
  kubeadm_ca_secret_name    = "${var.common_prefix}-kubeadm-ca/${var.cluster_name}/${var.environment}/v1"
  kubeadm_token_secret_name = "${var.common_prefix}-kubeadm-token/${var.cluster_name}/${var.environment}/v1"
  kubeadm_cert_secret_name  = "${var.common_prefix}-kubeadm-secret/${var.cluster_name}/${var.environment}/v1"
  global_tags = {
    environment      = "${var.environment}"
    provisioner      = "terraform"
    terraform_module = "kubernetes-cluster"
    k8s_cluster_name = "${var.cluster_name}"
    application      = "k8s"
  }
}


data "aws_iam_policy" "AmazonEC2ReadOnlyAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "template_cloudinit_config" "k8s_server" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/files/cloud-config-base.yaml", {})
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/install_k8s_utils.sh", {
      k8s_version = var.k8s_version
    })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/install_k8s.sh", {
      region                           = var.region,
      is_k8s_server                    = true,
      k8s_version                      = var.k8s_version,
      k8s_dns_domain                   = var.k8s_dns_domain,
      k8s_pod_subnet                   = var.k8s_pod_subnet,
      k8s_service_subnet               = var.k8s_service_subnet,
      kubeadm_ca_secret_name           = local.kubeadm_ca_secret_name,
      kubeadm_token_secret_name        = local.kubeadm_token_secret_name,
      kubeadm_cert_secret_name         = local.kubeadm_cert_secret_name,
      kubeconfig_secret_name           = local.kubeconfig_secret_name,
      kube_api_port                    = var.kube_api_port,
      control_plane_url                = aws_lb.k8s_server_lb.dns_name,
      install_nginx_ingress            = var.install_nginx_ingress,
      nginx_ingress_release            = var.nginx_ingress_release,
      efs_persistent_storage           = var.efs_persistent_storage,
      efs_csi_driver_release           = var.efs_csi_driver_release,
      efs_filesystem_id                = var.efs_persistent_storage ? aws_efs_file_system.k8s_persistent_storage[0].id : "",
      install_certmanager              = var.install_certmanager,
      certmanager_release              = var.certmanager_release,
      install_node_termination_handler = var.install_node_termination_handler,
      node_termination_handler_release = var.node_termination_handler_release,
      certmanager_email_address        = var.certmanager_email_address,
      extlb_listener_http_port         = var.extlb_listener_http_port,
      extlb_listener_https_port        = var.extlb_listener_https_port,
      default_secret_placeholder       = var.default_secret_placeholder,
      expose_kubeapi                   = var.expose_kubeapi,
      expose_kubeapi_locally           = var.expose_kubeapi_locally,
      k8s_tls_san_public               = local.k8s_tls_san_public
    })
  }
}

data "template_cloudinit_config" "k8s_worker" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/files/cloud-config-base.yaml", {})
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/install_k8s_utils.sh", {
      k8s_version = var.k8s_version
    })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/install_k8s_worker.sh", {
      region                     = var.region,
      is_k8s_server              = false,
      kubeadm_ca_secret_name     = local.kubeadm_ca_secret_name,
      kubeadm_token_secret_name  = local.kubeadm_token_secret_name,
      kubeadm_cert_secret_name   = local.kubeadm_cert_secret_name,
      kube_api_port              = var.kube_api_port,
      control_plane_url          = aws_lb.k8s_server_lb.dns_name,
      default_secret_placeholder = var.default_secret_placeholder,
    })
  }
}

data "aws_instances" "k8s_servers" {

  depends_on = [
    aws_autoscaling_group.k8s_servers_asg,
  ]

  instance_tags = {
    for tag, value in merge(local.global_tags, { k8s-instance-type = "k8s-server" }) : tag => value
  }

  instance_state_names = ["running"]
}

data "aws_instances" "k8s_workers" {

  depends_on = [
    aws_autoscaling_group.k8s_workers_asg,
  ]

  instance_tags = {
    for tag, value in merge(local.global_tags, { k8s-instance-type = "k8s-worker" }) : tag => value
  }

  instance_state_names = ["running"]
}