terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  environment = "staging"
  common_tags = {
    Project     = "localmart"
    Environment = local.environment
    ManagedBy   = "terraform"
    Owner       = "platform"
    CostCenter  = "engineering-${local.environment}"
  }
}

module "networking" {
  source = "../../modules/networking"

  environment        = local.environment
  aws_region         = var.aws_region
  vpc_cidr           = "10.1.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  nat_gateway_count  = 1

  tags = local.common_tags
}

module "dns_certs" {
  source = "../../modules/dns-certs"

  environment = local.environment
  root_domain = var.root_domain
  vpc_id      = module.networking.vpc_id

  tags = local.common_tags
}

module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  environment        = local.environment
  cluster_name       = "localmart-${local.environment}"
  log_retention_days = 30
  container_insights = true

  tags = local.common_tags
}

module "vault" {
  source = "../../modules/vault"

  environment             = local.environment
  aws_region              = var.aws_region
  vpc_id                  = module.networking.vpc_id
  private_subnet_ids      = module.networking.private_subnet_ids
  sg_vault_alb_id         = module.networking.sg_vault_alb_id
  sg_vault_task_id        = module.networking.sg_vault_task_id
  task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn           = module.iam.vault_task_role_arn
  ecs_cluster_arn         = module.ecs_cluster.cluster_arn
  ecs_cluster_name        = module.ecs_cluster.cluster_name
  log_group_name          = module.ecs_cluster.vault_log_group_name
  vault_ecr_repo_url      = module.ecs_cluster.vault_ecr_repo_url
  vault_task_count        = 1
  vault_cpu               = 512
  vault_memory            = 1024
  private_zone_id         = module.dns_certs.private_zone_id
  internal_domain         = "localmart.internal"
  acm_cert_arn            = module.dns_certs.acm_cert_arn
  efs_throughput_mode     = "bursting"

  tags = local.common_tags
}

module "database" {
  source = "../../modules/database"

  environment          = local.environment
  aws_region           = var.aws_region
  aws_account_id       = data.aws_caller_identity.current.account_id
  vpc_id               = module.networking.vpc_id
  isolated_subnet_ids  = module.networking.isolated_subnet_ids
  private_subnet_ids   = module.networking.private_subnet_ids
  sg_rds_id            = module.networking.sg_rds_id
  sg_rds_proxy_id      = module.networking.sg_rds_proxy_id
  cluster_identifier   = "localmart-${local.environment}"
  instance_class       = "db.t4g.large"
  instance_count       = 2
  backup_retention_period      = 14
  deletion_protection          = true
  performance_insights_enabled = true
  enable_proxy                 = true
  proxy_iam_role_arn           = module.iam.rds_proxy_role_arn

  tags = local.common_tags
}

module "iam" {
  source = "../../modules/iam"

  environment          = local.environment
  aws_region           = var.aws_region
  aws_account_id       = data.aws_caller_identity.current.account_id
  ecs_cluster_arn      = module.ecs_cluster.cluster_arn
  vault_kms_key_arn    = module.vault.vault_kms_key_arn
  database_kms_key_arn = module.database.database_kms_key_arn
  state_bucket_arn     = var.state_bucket_arn
  lock_table_arn       = var.lock_table_arn
  ecr_repo_arns        = values(module.ecs_cluster.ecr_repo_urls)

  tags = local.common_tags
}
