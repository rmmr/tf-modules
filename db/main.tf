resource "random_string" "unique_suffix" {
  length  = 8
  special = false
}

locals {
  unique_suffix = random_string.unique_suffix.result
  secret = {
    username = var.database_user
    password = var.database_password
  }
}

resource "aws_secretsmanager_secret" "_" {
  name = "${var.name}-secret-${local.unique_suffix}"
}

resource "aws_secretsmanager_secret_version" "_" {
  secret_id     = aws_secretsmanager_secret._.id
  secret_string = jsonencode(local.secret)
}

resource "aws_db_proxy" "_" {
  name                   = "${var.name}-proxy"
  debug_logging          = var.debug
  engine_family          = var.engine_family
  require_tls            = var.require_tls
  idle_client_timeout    = var.idle_client_timeout
  role_arn               = aws_iam_role.db_proxy.arn
  vpc_security_group_ids = var.security_group_ids
  vpc_subnet_ids         = var.subnet_ids

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret._.arn
  }

  tags = var.tags
}

resource "aws_db_proxy_default_target_group" "_" {
  db_proxy_name = aws_db_proxy._.name
  connection_pool_config {

  }
}

resource "aws_db_proxy_target" "_" {
  db_cluster_identifier = aws_rds_cluster._.cluster_identifier
  db_proxy_name         = aws_db_proxy._.name
  target_group_name     = aws_db_proxy_default_target_group._.name
}

resource "aws_db_subnet_group" "_" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_rds_cluster" "_" {
  cluster_identifier      = "${var.name}-cluster"
  db_subnet_group_name    = aws_db_subnet_group._.name
  vpc_security_group_ids  = var.security_group_ids
  availability_zones      = var.availability_zones
  engine                  = var.engine
  engine_version          = var.engine_version
  engine_mode             = var.engine_mode
  database_name           = var.database_name
  master_username         = local.secret.username
  master_password         = local.secret.password
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  skip_final_snapshot     = var.skip_final_snapshot
  tags                    = var.tags
}

resource "aws_rds_cluster_instance" "_" {
  count              = var.instance_count
  identifier         = "${var.name}-instance-${count.index}"
  cluster_identifier = aws_rds_cluster._.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster._.engine
  engine_version     = aws_rds_cluster._.engine_version
}

resource "aws_iam_policy" "db_proxy" {
  name   = "${var.name}-proxy-policy"
  policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"GetSecretValue",
      "Effect":"Allow",
      "Action":[
        "secretsmanager:GetSecretValue"
      ],
      "Resource":[
        "${aws_secretsmanager_secret._.arn}"
      ]
    },
    {
      "Sid":"DecryptSecretValue",
      "Effect":"Allow",
      "Action":[
        "kms:Decrypt"
      ],
      "Resource":"*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "db_proxy" {
  name               = "${var.name}-proxy-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "db_proxy" {
  role       = aws_iam_role.db_proxy.name
  policy_arn = aws_iam_policy.db_proxy.arn
}

