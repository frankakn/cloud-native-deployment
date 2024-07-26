provider "aws" {
  region = var.region
}

module "private-vpc" {
  region            = var.region
  my_public_ip_cidr = var.my_public_ip_cidr
  vpc_cidr_block    = var.vpc_cidr_block
  environment       = var.environment
  source            = "../../SelfManagedKubernetes/modules/private-vpc" # TODO refactor
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
  source             = "../../SelfManagedKubernetes/modules/bastion-host" # TODO refactor
}

output "bastion_host_ip" {
  value = module.bastion-host.bastion_ip
}

module "ecs-cluster" {
  vpc_id                 = module.private-vpc.vpc_id
  vpc_security_group_ids = [module.private-vpc.security_group_id]
  vpc_private_subnet_ids = module.private-vpc.private_subnet_ids
  vpc_public_subnet_ids  = module.private-vpc.public_subnet_ids
  key_name               = var.ssk_key_pair_name
  source                 = "../modules/ecs-cluster"
}


resource "aws_security_group" "allow-ingress" {
  vpc_id      = module.private-vpc.vpc_id
  name        = "allow-ingress"
  description = "security group that allows ingress traffic at port 80"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
      Name = "sg-allow-ingress-${var.environment}"
    }
}


resource "aws_alb" "ecs_alb" {
  name               = "ecs-alb-${var.environment}"
  #internal           = false
  #load_balancer_type = "application"
  security_groups    = [module.private-vpc.security_group_id, aws_security_group.allow-ingress.id]
  subnets            = module.private-vpc.public_subnet_ids

  tags = {
    Name = "ecs-alb-${var.environment}"
  }
}

resource "aws_iam_role" "ecs_service_role" {
  name               = "${var.environment}_ECS_ServiceRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_service_policy.json
}

data "aws_iam_policy_document" "ecs_service_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com",]
    }
  }
}

resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name   = "${var.environment}_ECS_ServiceRolePolicy"
  policy = data.aws_iam_policy_document.ecs_service_role_policy.json
  role   = aws_iam_role.ecs_service_role.id
}

data "aws_iam_policy_document" "ecs_service_role_policy" {
  statement {
    effect  = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
      "ec2:DescribeTags",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutSubscriptionFilter",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.environment}_ECS_TaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role_policy.json
}

data "aws_iam_policy_document" "task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_iam_role" {
  name               = "${var.environment}_ECS_TaskIAMRole"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role_policy.json
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family             = "my-ecs-task"
  network_mode       = "awsvpc"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_iam_role.arn
  cpu                = 256

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "dockergs"
      image     = "docker/getting-started:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "ecs_service" {
  name            = "my-ecs-service"
  cluster         = module.ecs-cluster.ecs_cluster_id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = 2
  #deployment_minimum_healthy_percent = var.ecs_task_deployment_minimum_healthy_percent
  #deployment_maximum_percent         = var.ecs_task_deployment_maximum_percent

  network_configuration {
    subnets         = module.private-vpc.private_subnet_ids
    security_groups = [module.private-vpc.security_group_id]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.service_target_group.arn
    container_name   = "dockergs"
    container_port   = 80
  }

  ## Spread tasks evenly accross all Availability Zones for High Availability
  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }
  
  ## Make use of all available space on the Container Instances
  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  ## Do not update desired count again to avoid a reset to this number on every deployment
  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [module.ecs-cluster.autoscaling_group, aws_alb_target_group.service_target_group, aws_alb_listener.alb_default_listener_http, aws_alb_listener_rule.http_listener_rule]
}

resource "aws_alb_listener" "alb_default_listener_http" {
  load_balancer_arn = aws_alb.ecs_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Access denied"
      status_code  = "403"
    }
  }
  
}


resource "aws_alb_listener_rule" "http_listener_rule" {
  listener_arn = aws_alb_listener.alb_default_listener_http.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.service_target_group.arn
  }

  
  condition {
    path_pattern {
      values = ["/*"]
    }
  }

}

resource "aws_alb_target_group" "service_target_group" {
  name                 = "${var.environment}-TargetGroup"
  port                 = "80"
  protocol             = "HTTP"
  target_type = "ip"
  vpc_id               = module.private-vpc.vpc_id
  deregistration_delay = 120

  health_check {
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
    interval            = "60"
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "30"
  }
  
  depends_on = [aws_alb.ecs_alb]
}

