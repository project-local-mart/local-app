terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  module_tags      = merge(var.tags, { Module = "vault" })
  vault_fqdn       = "vault.${var.internal_domain}"
  vault_image      = "${var.vault_ecr_repo_url}:${var.vault_image_tag}"

  # Vault configuration delivered via VAULT_LOCAL_CONFIG env var.
  # PRIVATE_IP and VAULT_NODE_ID are resolved at container startup by the
  # entrypoint wrapper (see container command below).
  # KMS key ID and region are resolved at Terraform plan time.
  vault_config = jsonencode({
    ui           = true
    log_level    = "info"
    log_format   = "json"
    cluster_name = "localmart-${var.environment}"

    # api_addr uses the internal ALB FQDN registered in Route53 private zone
    api_addr = "http://${local.vault_fqdn}:8200"

    listener = [
      {
        tcp = {
          address     = "0.0.0.0:8200"
          tls_disable = true # TLS terminated at ALB; ALB→task traffic stays in private subnet
          telemetry = {
            unauthenticated_metrics_access = false
          }
        }
      }
    ]

    storage = {
      raft = {
        path                  = "/vault/data"
        node_id               = "VAULT_NODE_PLACEHOLDER" # Replaced at startup by entrypoint
        performance_multiplier = 1
      }
    }

    seal = {
      awskms = {
        region     = var.aws_region
        kms_key_id = aws_kms_key.vault_unseal.key_id
      }
    }

    telemetry = {
      disable_hostname        = true
      enable_hostname_label   = true
      prometheus_retention_time = "24h"
    }

    default_lease_ttl = "768h"
    max_lease_ttl     = "8760h"
    disable_mlock     = true # Required for Fargate — containers cannot acquire IPC_LOCK
  })
}

# ─── KMS key for Vault auto-unseal ───────────────────────────────────────────

resource "aws_kms_key" "vault_unseal" {
  description             = "Vault auto-unseal key — localmart ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = merge(local.module_tags, { Name = "localmart-${var.environment}-vault-unseal", DataClassification = "confidential" })
}

resource "aws_kms_alias" "vault_unseal" {
  name          = "alias/localmart-${var.environment}-vault-unseal"
  target_key_id = aws_kms_key.vault_unseal.key_id
}

# ─── EFS for Vault Raft storage ───────────────────────────────────────────────

resource "aws_efs_file_system" "vault" {
  creation_token   = "localmart-${var.environment}-vault"
  encrypted        = true
  kms_key_id       = aws_kms_key.vault_unseal.arn
  throughput_mode  = var.efs_throughput_mode

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-vault-efs", BackupPolicy = "daily-7d", DataClassification = "confidential" })
}

resource "aws_efs_backup_policy" "vault" {
  file_system_id = aws_efs_file_system.vault.id
  backup_policy {
    status = "ENABLED"
  }
}

# Security group for EFS mount targets
resource "aws_security_group" "efs" {
  name        = "localmart-${var.environment}-vault-efs-sg"
  description = "Allow NFS from Vault ECS tasks."
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS from Vault tasks"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.sg_vault_task_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-vault-efs-sg" })
}

resource "aws_efs_mount_target" "vault" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.vault.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "vault" {
  file_system_id = aws_efs_file_system.vault.id

  posix_user {
    gid = 100
    uid = 100
  }

  root_directory {
    path = "/vault/data"
    creation_info {
      owner_gid   = 100
      owner_uid   = 100
      permissions = "0750"
    }
  }

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-vault-ap" })
}

# ─── Internal ALB ─────────────────────────────────────────────────────────────

resource "aws_lb" "vault" {
  name               = "localmart-${var.environment}-vault"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.sg_vault_alb_id]
  subnets            = var.private_subnet_ids

  enable_deletion_protection = var.environment == "prod"

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-vault-alb", PublicFacing = "false" })
}

resource "aws_lb_target_group" "vault" {
  name        = "localmart-${var.environment}-vault"
  port        = 8200
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/v1/sys/health?standbyok=true&sealedok=true&uninitcode=200"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-vault-tg" })
}

resource "aws_lb_listener" "vault_http" {
  load_balancer_arn = aws_lb.vault.arn
  port              = 8200
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault.arn
  }

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-vault-http-listener" })
}

# ─── Route53 CNAME for vault.localmart.internal ───────────────────────────────

resource "aws_route53_record" "vault" {
  zone_id = var.private_zone_id
  name    = "vault"
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.vault.dns_name]
}

# ─── ECS Task Definition ──────────────────────────────────────────────────────

resource "aws_ecs_task_definition" "vault" {
  family                   = "localmart-${var.environment}-vault"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.vault_cpu
  memory                   = var.vault_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  volume {
    name = "vault-data"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.vault.id
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2049
      authorization_config {
        access_point_id = aws_efs_access_point.vault.id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "vault"
      image     = local.vault_image
      essential = true

      # Entrypoint wrapper: resolve the Fargate task's private IP at runtime,
      # inject it as VAULT_API_ADDR / VAULT_CLUSTER_ADDR, then start Vault.
      # The VAULT_LOCAL_CONFIG is pre-populated by Terraform with static values;
      # node_id and cluster_addr reference the task's runtime IP.
      entryPoint = ["/bin/sh", "-c"]
      command = [
        <<-EOC
          set -e
          PRIVATE_IP=$(wget -qO- "$${ECS_CONTAINER_METADATA_URI_V4}/task" | grep -Eo '"IPv4Addresses":\["[0-9.]+"' | head -1 | grep -Eo '[0-9.]+$')
          export VAULT_API_ADDR="http://$${PRIVATE_IP}:8200"
          export VAULT_CLUSTER_ADDR="http://$${PRIVATE_IP}:8201"
          export VAULT_RAFT_NODE_ID="$(echo "$${ECS_CONTAINER_METADATA_URI_V4}" | grep -Eo '[a-f0-9]{32}$' || echo vault-node-1)"
          vault server -config=/vault/config/local.json
        EOC
      ]

      environment = [
        { name = "VAULT_LOCAL_CONFIG", value = local.vault_config },
        { name = "SKIP_SETCAP", value = "true" }, # Fargate: skip mlock capability set
      ]

      mountPoints = [
        {
          sourceVolume  = "vault-data"
          containerPath = "/vault/data"
          readOnly      = false
        }
      ]

      portMappings = [
        { containerPort = 8200, protocol = "tcp" },
        { containerPort = 8201, protocol = "tcp" },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "vault"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget -qO- http://localhost:8200/v1/sys/health?standbyok=true || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-vault" })
}

# ─── ECS Service ──────────────────────────────────────────────────────────────

resource "aws_ecs_service" "vault" {
  name            = "localmart-${var.environment}-vault"
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.vault.arn
  desired_count   = var.vault_task_count
  launch_type     = "FARGATE"

  # Pin to specific task definition revision on each deploy
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.sg_vault_task_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.vault.arn
    container_name   = "vault"
    container_port   = 8200
  }

  # Ignore task_definition changes after first deploy so that
  # image updates via CI don't cause Terraform drift.
  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [aws_efs_mount_target.vault, aws_lb_listener.vault_http]

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-vault", AutoScaling = "enabled" })
}
