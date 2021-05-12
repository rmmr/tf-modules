output "db_proxy_endpoint" {
  value = var.create_db_proxy ? aws_db_proxy._.0.endpoint : null
}

output "db_cluster_instance_endpoints" {
  value = aws_rds_cluster_instance._.*.endpoint
}
