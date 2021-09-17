output "db_proxy_endpoint" {
  value = var.create_db_proxy ? aws_db_proxy._.0.endpoint : null
}

output "db_cluster_endpoint" {
  value = local.is_aurora ? aws_rds_cluster._.0.endpoint : null
}

output "db_cluster_instance_endpoints" {
  value = aws_rds_cluster_instance._.*.endpoint
}

output "db_instance_endpoints" {
  value = aws_db_instance._.*.endpoint
}

output "db_endpoint" {
  value = var.create_db_proxy ? aws_db_proxy._.0.endpoint : local.is_aurora ? aws_rds_cluster._.0.endpoint : aws_db_instance._.0.endpoint
}
