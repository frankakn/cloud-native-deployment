output "k8s_dns_name" {
  value = var.create_extlb ? aws_lb.external_lb.*.dns_name : []
}

output "k8s_server_private_ips" {
  value = data.aws_instances.k8s_servers.*.private_ips
}

output "k8s_workers_private_ips" {
  value = data.aws_instances.k8s_workers.*.private_ips
}