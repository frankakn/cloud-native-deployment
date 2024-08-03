resource "aws_vpc_endpoint" "endpoint_for_ecs_agent" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.region}.ecs-agent"
  vpc_endpoint_type = "Interface"
  subnet_ids = var.vpc_private_subnet_ids
  security_group_ids = var.vpc_security_group_ids
}

resource "aws_vpc_endpoint" "endpoint_for_ecs_telemetry" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.region}.ecs-telemetry"
  vpc_endpoint_type = "Interface"
  subnet_ids = var.vpc_private_subnet_ids
  security_group_ids = var.vpc_security_group_ids
}

resource "aws_vpc_endpoint" "endpoint_for_ecs" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.region}.ecs"
  vpc_endpoint_type = "Interface"
  subnet_ids = var.vpc_private_subnet_ids
  security_group_ids = var.vpc_security_group_ids
}

resource "aws_iam_role" "ec2_instance_role" {
  name               = "${var.environment}_EC2_InstanceRole"
  assume_role_policy = data.aws_iam_policy_document.ec2_instance_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2_instance_role_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ec2_instance_role_profile" {
  name  = "${var.environment}_EC2_InstanceRoleProfile"
  role  = aws_iam_role.ec2_instance_role.id
}

data "aws_iam_policy_document" "ec2_instance_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "ecs.amazonaws.com"
      ]
    }
  }
}


data "template_file" "user_data_ecs_instance" {

  template = file("${path.module}/files/ecs.sh")

  vars = {
     cluster_name = var.ecs_cluster_name
  }

}

data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"]
}

resource "aws_launch_template" "ecs_lt" {

  name_prefix   = "ecs-template"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_role_profile.arn
  }

  block_device_mappings { 
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ecs-instance-${var.environment}"
    }
  }

  user_data = base64encode(data.template_file.user_data_ecs_instance.rendered)
}

resource "aws_autoscaling_group" "ecs_asg" {

  vpc_zone_identifier = var.vpc_private_subnet_ids
  desired_capacity    = 2
  max_size            = 10
  min_size            = 1

  launch_template {

    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged-${var.environment}"
    value               = true
    propagate_at_launch = true
  }

}


resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = "${var.environment}-example-ecs-capacity-provider-ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status = "ENABLED"
      target_capacity = 3
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs-provider-matching" {

  cluster_name = aws_ecs_cluster.ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

  default_capacity_provider_strategy {
    base = 1
    weight = 100
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
  }
}
