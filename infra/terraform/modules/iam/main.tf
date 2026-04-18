terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  module_tags = merge(var.tags, { Module = "iam" })
  partition   = "aws"
}

# ─── ECS Task Execution Role (shared by all services) ────────────────────────
# Grants ECS the ability to pull images from ECR and write logs to CloudWatch.

data "aws_iam_policy_document" "ecs_task_execution_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals { type = "Service"; identifiers = ["ecs-tasks.amazonaws.com"] }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "localmart-${var.environment}-ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume.json
  tags               = merge(local.module_tags, { Name = "localmart-${var.environment}-ecs-task-execution" })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_managed" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_execution_extra" {
  # Allow pulling from specific ECR repos
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:BatchCheckLayerAvailability"]
    resources = var.ecr_repo_arns
  }
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  # Allow reading secrets from Secrets Manager at task startup
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:${local.partition}:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:localmart/${var.environment}/*"]
  }
  # Allow decrypting secrets with the KMS keys used by Secrets Manager
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [var.vault_kms_key_arn, var.database_kms_key_arn]
  }
}

resource "aws_iam_role_policy" "ecs_task_execution_extra" {
  name   = "extra-permissions"
  role   = aws_iam_role.ecs_task_execution.id
  policy = data.aws_iam_policy_document.ecs_task_execution_extra.json
}

# ─── Vault Task Role ──────────────────────────────────────────────────────────
# Grants the Vault container permission to use its KMS auto-unseal key
# and to authenticate other services via the AWS IAM auth method.

data "aws_iam_policy_document" "vault_task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals { type = "Service"; identifiers = ["ecs-tasks.amazonaws.com"] }
  }
}

resource "aws_iam_role" "vault_task" {
  name               = "localmart-${var.environment}-vault-task"
  assume_role_policy = data.aws_iam_policy_document.vault_task_assume.json
  tags               = merge(local.module_tags, { Name = "localmart-${var.environment}-vault-task" })
}

data "aws_iam_policy_document" "vault_task_policy" {
  # KMS auto-unseal
  statement {
    effect    = "Allow"
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:DescribeKey", "kms:GenerateDataKey"]
    resources = [var.vault_kms_key_arn]
  }
  # Allow Vault to describe calling IAM entities for the AWS auth method
  statement {
    effect    = "Allow"
    actions   = ["iam:GetRole", "iam:GetUser", "ec2:DescribeInstances", "iam:GetInstanceProfile"]
    resources = ["*"]
  }
  # Vault audit logs to CloudWatch (if writing directly; audit to stdout is preferred)
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
    resources = ["arn:${local.partition}:logs:${var.aws_region}:${var.aws_account_id}:log-group:/localmart/${var.environment}/vault:*"]
  }
}

resource "aws_iam_role_policy" "vault_task" {
  name   = "vault-task-policy"
  role   = aws_iam_role.vault_task.id
  policy = data.aws_iam_policy_document.vault_task_policy.json
}

# ─── API Task Role ────────────────────────────────────────────────────────────
# The API task authenticates to Vault via the AWS IAM auth method.
# Vault then issues short-lived DB credentials. The task role itself
# needs no direct DB or KMS access.

data "aws_iam_policy_document" "api_task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals { type = "Service"; identifiers = ["ecs-tasks.amazonaws.com"] }
  }
}

resource "aws_iam_role" "api_task" {
  name               = "localmart-${var.environment}-api-task"
  assume_role_policy = data.aws_iam_policy_document.api_task_assume.json
  tags               = merge(local.module_tags, { Name = "localmart-${var.environment}-api-task" })
}

data "aws_iam_policy_document" "api_task_policy" {
  # S3 product images bucket (read/write pre-signed URL issuance)
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = ["arn:${local.partition}:s3:::localmart-product-images-${var.environment}/*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:${local.partition}:s3:::localmart-product-images-${var.environment}"]
  }
  # SES for transactional email
  statement {
    effect    = "Allow"
    actions   = ["ses:SendEmail", "ses:SendRawEmail"]
    resources = ["*"]
  }
  # Retrieve its own Vault token (Vault uses sts:GetCallerIdentity for IAM auth)
  statement {
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "api_task" {
  name   = "api-task-policy"
  role   = aws_iam_role.api_task.id
  policy = data.aws_iam_policy_document.api_task_policy.json
}

# ─── Worker Task Role ─────────────────────────────────────────────────────────

data "aws_iam_policy_document" "worker_task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals { type = "Service"; identifiers = ["ecs-tasks.amazonaws.com"] }
  }
}

resource "aws_iam_role" "worker_task" {
  name               = "localmart-${var.environment}-worker-task"
  assume_role_policy = data.aws_iam_policy_document.worker_task_assume.json
  tags               = merge(local.module_tags, { Name = "localmart-${var.environment}-worker-task" })
}

data "aws_iam_policy_document" "worker_task_policy" {
  # Workers read/write product images during POS sync
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = ["arn:${local.partition}:s3:::localmart-product-images-${var.environment}/*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:${local.partition}:s3:::localmart-product-images-${var.environment}"]
  }
  statement {
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "worker_task" {
  name   = "worker-task-policy"
  role   = aws_iam_role.worker_task.id
  policy = data.aws_iam_policy_document.worker_task_policy.json
}

# ─── RDS Proxy Role ───────────────────────────────────────────────────────────
# Allows RDS Proxy to retrieve the DB master password from Secrets Manager.

data "aws_iam_policy_document" "rds_proxy_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals { type = "Service"; identifiers = ["rds.amazonaws.com"] }
  }
}

resource "aws_iam_role" "rds_proxy" {
  name               = "localmart-${var.environment}-rds-proxy"
  assume_role_policy = data.aws_iam_policy_document.rds_proxy_assume.json
  tags               = merge(local.module_tags, { Name = "localmart-${var.environment}-rds-proxy" })
}

data "aws_iam_policy_document" "rds_proxy_policy" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:${local.partition}:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:localmart/${var.environment}/db-master-*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [var.database_kms_key_arn]
  }
}

resource "aws_iam_role_policy" "rds_proxy" {
  name   = "rds-proxy-policy"
  role   = aws_iam_role.rds_proxy.id
  policy = data.aws_iam_policy_document.rds_proxy_policy.json
}
