provider "aws" {
  region = "us-east-2"
}

resource "aws_autoscaling_policy" "target_group1" {
  name                   = "target-scaling-policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = var.autoscaling_group_1 

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    
    target_value = var.cpu_utilization
  }
}

resource "aws_autoscaling_policy" "target_group2" {
  name                   = "target-scaling-policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = var.autoscaling_group_2

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    
    target_value = var.cpu_utilization
  }
}