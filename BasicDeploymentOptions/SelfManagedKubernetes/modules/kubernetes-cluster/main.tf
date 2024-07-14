resource "aws_efs_file_system" "k8s_persistent_storage" {
  count          = var.efs_persistent_storage ? 1 : 0
  creation_token = "${var.common_prefix}-efs-persistent-storage-${var.environment}"
  encrypted      = true

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-efs-persistent-storage-${var.environment}")
    }
  )
}


resource "aws_efs_mount_target" "k8s_persistent_storage_mount_target" {
  count           = var.efs_persistent_storage ? length(var.vpc_private_subnets) : 0
  file_system_id  = aws_efs_file_system.k8s_persistent_storage[0].id
  subnet_id       = var.vpc_private_subnets[count.index]
  security_groups = [aws_security_group.efs_sg[0].id]
}

resource "aws_iam_instance_profile" "k8s_instance_profile" {
  name = "${var.common_prefix}-ec2-instance-profile--${var.environment}"
  role = aws_iam_role.k8s_iam_role.name

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-ec2-instance-profile--${var.environment}")
    }
  )
}

resource "aws_iam_role" "k8s_iam_role" {
  name = "${var.common_prefix}-iam-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-iam-role-${var.environment}")
    }
  )
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${var.common_prefix}-cluster-autoscaler-policy-${var.environment}"
  path        = "/"
  description = "Cluster autoscaler policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeLaunchTemplateVersions"
        ],
        Resource = [
          "${aws_launch_template.k8s_server.arn}",
          "${aws_launch_template.k8s_worker.arn}"
        ],
        Condition = {
          StringEquals = {
            for tag, value in local.global_tags : "aws:ResourceTag/${tag}" => value
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:DescribeTags",
        ],
        Resource = [
          "${aws_autoscaling_group.k8s_servers_asg.arn}",
          "${aws_autoscaling_group.k8s_workers_asg.arn}"
        ],
        Condition = {
          StringEquals = {
            for tag, value in local.global_tags : "aws:ResourceTag/${tag}" => value
          }
        }
      },
    ]
  })

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-cluster-autoscaler-policy-${var.environment}")
    }
  )
}

resource "aws_iam_policy" "aws_efs_csi_driver_policy" {
  count       = var.efs_persistent_storage ? 1 : 0
  name        = "${var.common_prefix}-csi-driver-policy-${var.environment}"
  path        = "/"
  description = "AWS EFS CSI driver policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets",
          "ec2:DescribeAvailabilityZones"
        ],
        Resource = [
          "*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:CreateAccessPoint"
        ],
        Resource = [
          "*"
        ],
        Condition = {
          StringLike = {
            "aws:RequestTag/efs.csi.aws.com/cluster" = "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:TagResource"
        ],
        Resource = [
          "*"
        ],
        Condition = {
          StringLike = {
            "aws:ResourceTag/efs.csi.aws.com/cluster" = "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DeleteAccessPoint"
        ],
        Resource = [
          "*"
        ],
        Condition = {
          StringEquals = {
            "aws:ResourceTag/efs.csi.aws.com/cluster" = "true"
          }
        }
      },
    ]
  })

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-csi-driver-policy-${var.environment}")
    }
  )
}

resource "aws_iam_policy" "allow_secrets_manager" {
  name        = "${var.common_prefix}-secrets-manager-policy-${var.environment}"
  path        = "/"
  description = "Secrets Manager Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets",
          "secretsmanager:CreateSecret",
          "secretsmanager:PutSecretValue"
        ],
        Resource = [
          "${aws_secretsmanager_secret.kubeconfig_secret.arn}",
          "${aws_secretsmanager_secret.kubeadm_ca.arn}",
          "${aws_secretsmanager_secret.kubeadm_token.arn}",
          "${aws_secretsmanager_secret.kubeadm_cert.arn}"
        ],
        Condition = {
          StringEquals = {
            for tag, value in local.global_tags : "aws:ResourceTag/${tag}" => value
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets"
        ],
        Resource = [
          "*"
        ],
      }
    ]
  })

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-secrets-manager-policy-${var.environment}")
    }
  )
}

resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = aws_iam_role.k8s_iam_role.name
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}

resource "aws_iam_role_policy_attachment" "attach_cluster_autoscaler_policy" {
  role       = aws_iam_role.k8s_iam_role.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

resource "aws_iam_role_policy_attachment" "attach_aws_efs_csi_driver_policy" {
  count      = var.efs_persistent_storage ? 1 : 0
  role       = aws_iam_role.k8s_iam_role.name
  policy_arn = aws_iam_policy.aws_efs_csi_driver_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "attach_allow_secrets_manager_policy" {
  role       = aws_iam_role.k8s_iam_role.name
  policy_arn = aws_iam_policy.allow_secrets_manager.arn
}

resource "aws_iam_role_policy_attachment" "attach_ec2_ro_policy" {
  role       = aws_iam_role.k8s_iam_role.name
  policy_arn = data.aws_iam_policy.AmazonEC2ReadOnlyAccess.arn
}

resource "aws_autoscaling_group" "k8s_servers_asg" {
  name                      = "${var.common_prefix}-servers-asg-${var.environment}"
  wait_for_capacity_timeout = "5m"
  vpc_zone_identifier       = var.vpc_private_subnets

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, target_group_arns]
  }

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 20
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.k8s_server.id
        version            = "$Latest"
      }

      dynamic "override" {
        for_each = var.instance_types
        content {
          instance_type     = override.value
          weighted_capacity = "1"
        }
      }
    }
  }

  desired_capacity          = var.k8s_server_desired_capacity
  min_size                  = var.k8s_server_min_capacity
  max_size                  = var.k8s_server_max_capacity
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true

  dynamic "tag" {
    for_each = local.global_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.common_prefix}-server-${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s-instance-type"
    value               = "k8s-server"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = ""
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = ""
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "k8s_workers_asg" {
  name                = "${var.common_prefix}-workers-asg-${var.environment}"
  vpc_zone_identifier = var.vpc_private_subnets

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, target_group_arns]
  }

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 20
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.k8s_worker.id
        version            = "$Latest"
      }

      dynamic "override" {
        for_each = var.instance_types
        content {
          instance_type     = override.value
          weighted_capacity = "1"
        }
      }
    }
  }

  desired_capacity          = var.k8s_worker_desired_capacity
  min_size                  = var.k8s_worker_min_capacity
  max_size                  = var.k8s_worker_max_capacity
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true

  dynamic "tag" {
    for_each = local.global_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.common_prefix}-worker-${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s-instance-type"
    value               = "k8s-worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = ""
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = ""
    propagate_at_launch = true
  }
}

resource "aws_lb" "k8s_server_lb" {
  name               = "${var.common_prefix}-int-lb-${var.environment}"
  load_balancer_type = "network"
  internal           = "true"
  subnets            = var.vpc_private_subnets

  enable_cross_zone_load_balancing = true

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-int-lb-${var.environment}")
    }
  )
}

resource "aws_lb_listener" "k8s_server_listener" {
  load_balancer_arn = aws_lb.k8s_server_lb.arn

  protocol = "TCP"
  port     = var.kube_api_port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_server_tg.arn
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-kubeapi-listener-${var.environment}")
    }
  )
}

resource "aws_lb_target_group" "k8s_server_tg" {
  port               = var.kube_api_port
  protocol           = "TCP"
  vpc_id             = var.vpc_id
  preserve_client_ip = false

  depends_on = [
    aws_lb.k8s_server_lb
  ]

  health_check {
    protocol = "TCP"
    interval = 10
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-internal-lb-tg-kubeapi-${var.environment}")
    }
  )
}

resource "aws_autoscaling_attachment" "k8s_server_target_kubeapi" {

  depends_on = [
    aws_autoscaling_group.k8s_servers_asg,
    aws_lb_target_group.k8s_server_tg
  ]

  autoscaling_group_name = aws_autoscaling_group.k8s_servers_asg.name
  lb_target_group_arn    = aws_lb_target_group.k8s_server_tg.arn
}

resource "aws_lb" "external_lb" {
  count              = var.create_extlb ? 1 : 0
  name               = "${var.common_prefix}-ext-lb-${var.environment}"
  load_balancer_type = "network"
  internal           = "false"
  subnets            = var.vpc_public_subnets

  enable_cross_zone_load_balancing = true

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-ext-lb-${var.environment}")
    }
  )
}

# HTTP
resource "aws_lb_listener" "external_lb_listener_http" {
  count             = var.create_extlb ? 1 : 0
  load_balancer_arn = aws_lb.external_lb[count.index].arn

  protocol = "TCP"
  port     = var.extlb_http_port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external_lb_tg_http[count.index].arn
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-http-listener-${var.environment}")
    }
  )
}

resource "aws_lb_target_group" "external_lb_tg_http" {
  count             = var.create_extlb ? 1 : 0
  port              = var.extlb_listener_http_port
  protocol          = "TCP"
  vpc_id            = var.vpc_id
  proxy_protocol_v2 = false

  depends_on = [
    aws_lb.external_lb
  ]

  health_check {
    protocol = "TCP"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-ext-lb-tg-http-${var.environment}")
    }
  )
}

resource "aws_autoscaling_attachment" "target_http" {
  count = var.create_extlb ? 1 : 0
  depends_on = [
    aws_autoscaling_group.k8s_workers_asg,
    aws_lb_target_group.external_lb_tg_http
  ]

  autoscaling_group_name = aws_autoscaling_group.k8s_workers_asg.name
  lb_target_group_arn    = aws_lb_target_group.external_lb_tg_http[count.index].arn
}

# HTTPS
resource "aws_lb_listener" "external_lb_listener_https" {
  count             = var.create_extlb ? 1 : 0
  load_balancer_arn = aws_lb.external_lb[count.index].arn

  protocol = "TCP"
  port     = var.extlb_https_port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external_lb_tg_https[count.index].arn
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-https-listener-${var.environment}")
    }
  )
}

resource "aws_lb_target_group" "external_lb_tg_https" {
  count             = var.create_extlb ? 1 : 0
  port              = var.extlb_listener_https_port
  protocol          = "TCP"
  vpc_id            = var.vpc_id
  proxy_protocol_v2 = true

  depends_on = [
    aws_lb.external_lb
  ]

  health_check {
    protocol = "TCP"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-ext-lb-tg-https-${var.environment}")
    }
  )
}

resource "aws_autoscaling_attachment" "target_https" {
  count = var.create_extlb ? 1 : 0
  depends_on = [
    aws_autoscaling_group.k8s_workers_asg,
    aws_lb_target_group.external_lb_tg_https
  ]

  autoscaling_group_name = aws_autoscaling_group.k8s_workers_asg.name
  lb_target_group_arn    = aws_lb_target_group.external_lb_tg_https[count.index].arn
}

# kubeapi

resource "aws_lb_listener" "external_lb_listener_kubeapi" {
  count             = var.expose_kubeapi ? 1 : 0
  load_balancer_arn = aws_lb.external_lb[count.index].arn

  protocol = "TCP"
  port     = var.kube_api_port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external_lb_tg_kubeapi[count.index].arn
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-kubeapi-listener-${var.environment}")
    }
  )
}

resource "aws_lb_target_group" "external_lb_tg_kubeapi" {
  count    = var.expose_kubeapi ? 1 : 0
  port     = var.kube_api_port
  protocol = "TCP"
  vpc_id   = var.vpc_id

  depends_on = [
    aws_lb.external_lb
  ]

  health_check {
    protocol = "TCP"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-ext-lb-tg-kubeapi-${var.environment}")
    }
  )
}

resource "aws_autoscaling_attachment" "target_kubeapi" {
  count = var.expose_kubeapi ? 1 : 0
  depends_on = [
    aws_autoscaling_group.k8s_servers_asg,
    aws_lb_target_group.external_lb_tg_kubeapi
  ]

  autoscaling_group_name = aws_autoscaling_group.k8s_servers_asg.name
  lb_target_group_arn    = aws_lb_target_group.external_lb_tg_kubeapi[count.index].arn
}

resource "aws_secretsmanager_secret" "kubeconfig_secret" {
  name        = local.kubeconfig_secret_name
  description = "Kubeconfig k8s. Cluster name: ${var.cluster_name}, environment: ${var.environment}"
  recovery_window_in_days = 0

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${local.kubeconfig_secret_name}")
    }
  )
}

resource "aws_secretsmanager_secret" "kubeadm_ca" {
  name        = local.kubeadm_ca_secret_name
  description = "Kubeadm CA. Cluster name: ${var.cluster_name}, environment: ${var.environment}"
  recovery_window_in_days = 0

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${local.kubeadm_ca_secret_name}")
    }
  )
}

resource "aws_secretsmanager_secret" "kubeadm_token" {
  name        = local.kubeadm_token_secret_name
  description = "Kubeadm token. Cluster name: ${var.cluster_name}, environment: ${var.environment}"
  recovery_window_in_days = 0

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${local.kubeadm_token_secret_name}")
    }
  )
}

resource "aws_secretsmanager_secret" "kubeadm_cert" {
  name        = local.kubeadm_cert_secret_name
  description = "Kubeadm cert. Cluster name: ${var.cluster_name}, environment: ${var.environment}"
  recovery_window_in_days = 0

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${local.kubeadm_cert_secret_name}")
    }
  )
}

# secret default values

resource "aws_secretsmanager_secret_version" "kubeconfig_secret_default" {
  secret_id     = aws_secretsmanager_secret.kubeconfig_secret.id
  secret_string = var.default_secret_placeholder
}

resource "aws_secretsmanager_secret_version" "kubeadm_ca_default" {
  secret_id     = aws_secretsmanager_secret.kubeadm_ca.id
  secret_string = var.default_secret_placeholder
}

resource "aws_secretsmanager_secret_version" "kubeadm_token_default" {
  secret_id     = aws_secretsmanager_secret.kubeadm_token.id
  secret_string = var.default_secret_placeholder
}

resource "aws_secretsmanager_secret_version" "kubeadm_cert_default" {
  secret_id     = aws_secretsmanager_secret.kubeadm_cert.id
  secret_string = var.default_secret_placeholder
}

# Secret Policies

resource "aws_secretsmanager_secret_policy" "kubeconfig_secret_policy" {
  secret_arn = aws_secretsmanager_secret.kubeconfig_secret.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "${aws_iam_role.k8s_iam_role.arn}"
        },
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets",
          "secretsmanager:CreateSecret",
          "secretsmanager:PutSecretValue"
        ]
        Resource = [
          "${aws_secretsmanager_secret.kubeconfig_secret.arn}"
        ]
      }
    ]
  })
}

resource "aws_security_group" "k8s_sg" {
  vpc_id      = var.vpc_id
  name        = "k8s_sg"
  description = "Kubernetes ingress rules"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-allow-strict-${var.environment}")
    }
  )
}

resource "aws_security_group_rule" "ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.k8s_sg.id
}

resource "aws_security_group_rule" "ingress_kubeapi" {
  type              = "ingress"
  from_port         = var.kube_api_port
  to_port           = var.kube_api_port
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_subnet_cidr]
  security_group_id = aws_security_group.k8s_sg.id
}

resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.my_public_ip_cidr, var.vpc_subnet_cidr]
  security_group_id = aws_security_group.k8s_sg.id
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s_sg.id
}

resource "aws_security_group_rule" "allow_lb_http_traffic" {
  count             = var.create_extlb ? 1 : 0
  type              = "ingress"
  from_port         = var.extlb_listener_http_port
  to_port           = var.extlb_listener_http_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s_sg.id
}

resource "aws_security_group_rule" "allow_lb_https_traffic" {
  count             = var.create_extlb ? 1 : 0
  type              = "ingress"
  from_port         = var.extlb_listener_https_port
  to_port           = var.extlb_listener_https_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s_sg.id
}

resource "aws_security_group_rule" "allow_lb_kubeapi_traffic" {
  count             = var.create_extlb && var.expose_kubeapi ? 1 : 0
  type              = "ingress"
  from_port         = var.kube_api_port
  to_port           = var.kube_api_port
  protocol          = "tcp"
  cidr_blocks       = [var.my_public_ip_cidr]
  security_group_id = aws_security_group.k8s_sg.id
}

resource "aws_security_group" "efs_sg" {
  count       = var.efs_persistent_storage ? 1 : 0
  vpc_id      = var.vpc_id
  name        = "${var.common_prefix}-efs-sg-${var.environment}"
  description = "Allow EFS access from VPC subnets"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_subnet_cidr]
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-efs-sg-${var.environment}")
    }
  )
}

resource "aws_launch_template" "k8s_server" {
  name_prefix   = "${var.common_prefix}-server-tpl-${var.environment}"
  image_id      = var.ami
  instance_type = var.default_instance_type
  user_data     = data.template_cloudinit_config.k8s_server.rendered

  lifecycle {
    create_before_destroy = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.k8s_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
      encrypted   = true
    }
  }

  key_name = var.ssk_key_pair_name

  network_interfaces {
    associate_public_ip_address = var.ec2_associate_public_ip_address
    security_groups             = [aws_security_group.k8s_sg.id]
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-server-tpl-${var.environment}")
    }
  )
}

resource "aws_launch_template" "k8s_worker" {
  name_prefix   = "${var.common_prefix}-worker-tpl-${var.environment}"
  image_id      = var.ami
  instance_type = var.default_instance_type
  user_data     = data.template_cloudinit_config.k8s_worker.rendered

  lifecycle {
    create_before_destroy = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.k8s_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
      encrypted   = true
    }
  }

  key_name = var.ssk_key_pair_name

  network_interfaces {
    associate_public_ip_address = var.ec2_associate_public_ip_address
    security_groups             = [aws_security_group.k8s_sg.id]
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-worker-tpl-${var.environment}")
    }
  )
}