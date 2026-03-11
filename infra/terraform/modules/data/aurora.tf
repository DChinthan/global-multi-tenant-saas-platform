resource "random_password" "aurora_master_password" {
  count   = var.enable_aurora ? 1 : 0
  length  = 24
  special = true
}

resource "aws_db_subnet_group" "aurora" {
  count      = var.enable_aurora ? 1 : 0
  name       = "${local.name_prefix}-aurora-subnet-group"
  subnet_ids = var.private_data_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aurora-subnet-group"
  })
}

resource "aws_security_group" "aurora" {
  count       = var.enable_aurora ? 1 : 0
  name        = "${local.name_prefix}-aurora-sg"
  description = "Security group for Aurora PostgreSQL"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres access from application layer"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aurora-sg"
  })
}

resource "aws_rds_cluster" "aurora" {
  count                        = var.enable_aurora ? 1 : 0
  cluster_identifier           = "${local.name_prefix}-aurora-pg"
  engine                       = "aurora-postgresql"
  engine_version               = var.aurora_engine_version
  database_name                = var.aurora_database_name
  master_username              = var.aurora_master_username
  master_password              = random_password.aurora_master_password[0].result
  db_subnet_group_name         = aws_db_subnet_group.aurora[0].name
  vpc_security_group_ids       = [aws_security_group.aurora[0].id]
  storage_encrypted            = true
  kms_key_id                   = aws_kms_key.data.arn
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = "03:00-05:00"
  preferred_maintenance_window = "sun:06:00-sun:07:00"
  deletion_protection          = var.enable_deletion_protection
  skip_final_snapshot          = var.enable_deletion_protection ? false : true

  serverlessv2_scaling_configuration {
    min_capacity = var.aurora_min_capacity
    max_capacity = var.aurora_max_capacity
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aurora-cluster"
  })
}

resource "aws_rds_cluster_instance" "aurora" {
  count               = var.enable_aurora ? var.aurora_instance_count : 0
  identifier          = "${local.name_prefix}-aurora-instance-${count.index + 1}"
  cluster_identifier  = aws_rds_cluster.aurora[0].id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.aurora[0].engine
  engine_version      = aws_rds_cluster.aurora[0].engine_version
  publicly_accessible = false

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aurora-instance-${count.index + 1}"
  })
}