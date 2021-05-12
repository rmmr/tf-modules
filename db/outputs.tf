output "db_proxy_endpoint" {
  value = aws_db_proxy._.0.endpoint
}

output "db_cluster_instance_endpoints" {
  value = aws_rds_cluster_instance._.*.endpoint
}
