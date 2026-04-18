terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

locals {
  module_tags = merge(var.tags, { Module = "database" })
}

# ─── KMS key for RDS encryption ───────────────────────────────────────────────

resource "aws_kms_key" "rds" {
  description             = "Aurora PostgreSQL encryption key — localmart ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = merge(local.module_tags, { Name = "localmart-${var.environment}-rds-kms", DataClassification = "confidential" })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/localmart-${var.environment}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# ─── Master password in Secrets Manager ──────────────────────────────────────
# Aurora generates its own password on creation; we store the random password
# we generate here in Secrets Manager so RDS Proxy and Vault can retrieve it.

resource "random_password" "master" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_master" {
  name                    = "localmart/${var.environment}/db-master"
  description             = "Aurora master credentials — localmart ${var.environment}"
  kms_key_id              = aws_kms_key.rds.arn
  recovery_window_in_days = var.environment == "prod" ? 30 : 0
  tags                    = merge(local.module_tags, { Name = "localmart-${var.environment}-db-master", DataClassification = "confidential" })
}

resource "aws_secretsmanager_secret_version" "db_master" {
  secret_id = aws_secretsmanager_secret.db_master.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    engine   = "postgres"
    host     = aws_rds_cluster.main.endpoint
    port     = 5432
    dbname   = var.database_name
  })
}

# ─── Subnet group ─────────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name        = "localmart-${var.environment}"
  description = "Isolated subnets for the localmart ${var.environment} Aurora cluster."
  subnet_ids  = var.isolated_subnet_ids
  tags        = merge(local.module_tags, { Name = "localmart-${var.environment}-db-subnet-group" })
}

# ─── Cluster parameter group ──────────────────────────────────────────────────
# PostGIS is not enabled via parameter group; run CREATE EXTENSION postgis
# in the Drizzle migration runner after the cluster is up.

resource "aws_rds_cluster_parameter_group" "main" {
  name        = "localmart-${var.environment}-aurora-pg16"
  family      = "aurora-postgresql16"
  description = "Cluster parameters for localmart ${var.environment}."

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = var.environment == "prod" ? "1000" : "500" # Log slow queries (ms)
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-aurora-pg16-cpg" })
}

resource "aws_db_parameter_group" "main" {
  name        = "localmart-${var.environment}-pg16-instance"
  family      = "aurora-postgresql16"
  description = "Instance parameters for localmart ${var.environment}."
  tags        = merge(local.module_tags, { Name = "localmart-${var.environment}-pg16-instance-pg" })
}

# ─── Aurora Cluster ───────────────────────────────────────────────────────────

resource "aws_rds_cluster" "main" {
  cluster_identifier              = var.cluster_identifier
  engine                          = "aurora-postgresql"
  engine_version                  = var.engine_version
  database_name                   = var.database_name
  master_username                 = var.master_username
  master_password                 = random_password.master.result
  db_subnet_group_name            = aws_db_subnet_group.main.name
  vpc_security_group_ids          = [var.sg_rds_id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.rds.arn
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = "03:00-04:00"
  preferred_maintenance_window    = "sun:04:00-sun:05:00"
  deletion_protection             = var.deletion_protection
  skip_final_snapshot             = var.environment == "dev"
  final_snapshot_identifier       = var.environment != "dev" ? "${var.cluster_identifier}-final-snapshot" : null
  enabled_cloudwatch_logs_exports = ["postgresql"]
  apply_immediately               = var.environment == "dev"

  tags = merge(local.module_tags, { Name = var.cluster_identifier, BackupPolicy = "daily-${var.backup_retention_period}d", DataClassification = "confidential" })
}

# ─── Aurora Instances ─────────────────────────────────────────────────────────
# Instance 0 is always the writer. Instances 1+ are readers.

resource "aws_rds_cluster_instance" "main" {
  count                        = var.instance_count
  identifier                   = "${var.cluster_identifier}-${count.index}"
  cluster_identifier           = aws_rds_cluster.main.id
  instance_class               = var.instance_class
  engine                       = aws_rds_cluster.main.engine
  engine_version               = aws_rds_cluster.main.engine_version
  db_parameter_group_name      = aws_db_parameter_group.main.name
  db_subnet_group_name         = aws_db_subnet_group.main.name
  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? aws_kms_key.rds.arn : null
  monitoring_interval          = 60
  auto_minor_version_upgrade   = true
  apply_immediately            = var.environment == "dev"

  tags = merge(local.module_tags, {
    Name = "${var.cluster_identifier}-${count.index}"
    Role = count.index == 0 ? "writer" : "reader"
  })
}

# ─── RDS Proxy ────────────────────────────────────────────────────────────────

resource "aws_db_proxy" "main" {
  count                  = var.enable_proxy ? 1 : 0
  name                   = "localmart-${var.environment}"
  debug_logging          = var.environment != "prod"
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = 1800
  require_tls            = true
  role_arn               = var.proxy_iam_role_arn
  vpc_security_group_ids = [var.sg_rds_proxy_id]
  vpc_subnet_ids         = var.private_subnet_ids

  auth {
    auth_scheme               = "SECRETS"
    secret_arn                = aws_secretsmanager_secret.db_master.arn
    iam_auth                  = "DISABLED"
    client_password_auth_type = "POSTGRES_SCRAM_SHA_256"
  }

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-rds-proxy" })
}

resource "aws_db_proxy_default_target_group" "main" {
  count         = var.enable_proxy ? 1 : 0
  db_proxy_name = aws_db_proxy.main[0].name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "main" {
  count                 = var.enable_proxy ? 1 : 0
  db_cluster_identifier = aws_rds_cluster.main.cluster_identifier
  db_proxy_name         = aws_db_proxy.main[0].name
  target_group_name     = aws_db_proxy_default_target_group.main[0].name
}

# ─── Enhanced Monitoring IAM Role ─────────────────────────────────────────────

data "aws_iam_policy_document" "rds_enhanced_monitoring_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals { type = "Service"; identifiers = ["monitoring.rds.amazonaws.com"] }
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name               = "localmart-${var.environment}-rds-monitoring"
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring_assume.json
  tags               = local.module_tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
