output "ecs_cluster_id" {
  value = aws_ecs_cluster.ecs_cluster.id
}

output "ecs_capacity_provider_name" {
    value = aws_ecs_capacity_provider.ecs_capacity_provider.name
}

output "autoscaling_group" {
    value = aws_autoscaling_group.ecs_asg
}