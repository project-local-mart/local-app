terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  module_tags = merge(var.tags, { Module = "networking" })

  az_count = length(var.availability_zones)

  # Subnet CIDR strategy using /20 blocks within the VPC /16.
  # Indices 0-2   → public   (10.x.0.0/20, 10.x.16.0/20, 10.x.32.0/20)
  # Indices 4-6   → private  (10.x.64.0/20, 10.x.80.0/20, 10.x.96.0/20)
  # Indices 8-10  → isolated (10.x.128.0/20, 10.x.144.0/20, 10.x.160.0/20)
  public_subnet_cidrs   = [for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnet_cidrs  = [for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 4, i + 4)]
  isolated_subnet_cidrs = [for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 4, i + 8)]
}

# ─── VPC ─────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(local.module_tags, { Name = "localmart-${var.environment}" })
}

# ─── Subnets ─────────────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  count                   = local.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false # Instances should use EIPs or ALBs
  tags = merge(local.module_tags, {
    Name = "localmart-${var.environment}-public-${var.availability_zones[count.index]}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count             = local.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = merge(local.module_tags, {
    Name = "localmart-${var.environment}-private-${var.availability_zones[count.index]}"
    Tier = "private"
  })
}

resource "aws_subnet" "isolated" {
  count             = local.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.isolated_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = merge(local.module_tags, {
    Name = "localmart-${var.environment}-isolated-${var.availability_zones[count.index]}"
    Tier = "isolated"
  })
}

# ─── Internet Gateway ────────────────────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.module_tags, { Name = "localmart-${var.environment}-igw" })
}

# ─── Elastic IPs for NAT Gateways ────────────────────────────────────────────

resource "aws_eip" "nat" {
  count  = var.nat_gateway_count
  domain = "vpc"
  tags   = merge(local.module_tags, { Name = "localmart-${var.environment}-nat-eip-${count.index}" })
}

# ─── NAT Gateways ────────────────────────────────────────────────────────────

resource "aws_nat_gateway" "main" {
  count         = var.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.main]
  tags          = merge(local.module_tags, { Name = "localmart-${var.environment}-nat-${count.index}" })
}

# ─── Route Tables ────────────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = local.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Each private subnet routes through its own NAT GW in prod, or the single NAT GW otherwise.
resource "aws_route_table" "private" {
  count  = local.az_count
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[min(count.index, var.nat_gateway_count - 1)].id
  }
  tags = merge(local.module_tags, {
    Name = "localmart-${var.environment}-private-rt-${var.availability_zones[count.index]}"
  })
}

resource "aws_route_table_association" "private" {
  count          = local.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Isolated subnets have no route to the internet — local VPC traffic only.
resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.module_tags, { Name = "localmart-${var.environment}-isolated-rt" })
}

resource "aws_route_table_association" "isolated" {
  count          = local.az_count
  subnet_id      = aws_subnet.isolated[count.index].id
  route_table_id = aws_route_table.isolated.id
}

# ─── VPC Endpoints ────────────────────────────────────────────────────────────

# Gateway endpoints (free — no per-hour charge)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat([aws_route_table.public.id, aws_route_table.isolated.id], aws_route_table.private[*].id)
  tags              = merge(local.module_tags, { Name = "localmart-${var.environment}-vpce-s3" })
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat([aws_route_table.public.id, aws_route_table.isolated.id], aws_route_table.private[*].id)
  tags              = merge(local.module_tags, { Name = "localmart-${var.environment}-vpce-dynamodb" })
}

# Interface endpoints (per-hour charge — keep private subnet traffic inside AWS)
locals {
  interface_endpoint_services = [
    "ecr.api",
    "ecr.dkr",
    "ecs",
    "ecs-agent",
    "ecs-telemetry",
    "logs",
    "ssm",
    "ssmmessages",
    "ec2messages",
    "secretsmanager",
    "kms",
  ]
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "localmart-${var.environment}-vpce-sg"
  description = "Allow HTTPS from within the VPC to interface endpoints."
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-vpce-sg" })
}

resource "aws_vpc_endpoint" "interface" {
  for_each            = toset(local.interface_endpoint_services)
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  tags                = merge(local.module_tags, { Name = "localmart-${var.environment}-vpce-${each.value}" })
}

# ─── Security Groups ─────────────────────────────────────────────────────────

# Vault ALB — internal ALB reachable from private subnets only
resource "aws_security_group" "vault_alb" {
  name        = "localmart-${var.environment}-vault-alb-sg"
  description = "Vault internal ALB. Allows 8200 inbound from VPC private subnets."
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Vault API from VPC"
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-vault-alb-sg" })
}

# Vault ECS tasks
resource "aws_security_group" "vault_task" {
  name        = "localmart-${var.environment}-vault-task-sg"
  description = "Vault ECS tasks. Allows 8200 from Vault ALB, 8201 for Raft cluster traffic."
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Vault API from ALB"
    from_port       = 8200
    to_port         = 8200
    protocol        = "tcp"
    security_groups = [aws_security_group.vault_alb.id]
  }

  ingress {
    description = "Raft cluster port (peer-to-peer)"
    from_port   = 8201
    to_port     = 8201
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-vault-task-sg" })
}

# API ECS tasks
resource "aws_security_group" "api_task" {
  name        = "localmart-${var.environment}-api-task-sg"
  description = "Hono API ECS tasks."
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-api-task-sg" })
}

# Worker ECS tasks
resource "aws_security_group" "worker_task" {
  name        = "localmart-${var.environment}-worker-task-sg"
  description = "BullMQ worker ECS tasks."
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-worker-task-sg" })
}

# RDS Proxy
resource "aws_security_group" "rds_proxy" {
  name        = "localmart-${var.environment}-rds-proxy-sg"
  description = "RDS Proxy. Accepts Postgres from API and worker tasks."
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Postgres from API tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.api_task.id]
  }

  ingress {
    description     = "Postgres from worker tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.worker_task.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-rds-proxy-sg" })
}

# Aurora cluster — accepts only from RDS Proxy
resource "aws_security_group" "rds" {
  name        = "localmart-${var.environment}-rds-sg"
  description = "Aurora cluster. Accepts Postgres from RDS Proxy only."
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Postgres from RDS Proxy"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_proxy.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-rds-sg" })
}

# ─── VPC Flow Logs ────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_vpc_flow_logs ? 1 : 0
  name              = "/localmart/${var.environment}/vpc-flow-logs"
  retention_in_days = 30
  tags              = merge(local.module_tags, { Name = "localmart-${var.environment}-flow-logs" })
}

data "aws_iam_policy_document" "flow_logs_assume_role" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals { type = "Service"; identifiers = ["vpc-flow-logs.amazonaws.com"] }
  }
}

resource "aws_iam_role" "flow_logs" {
  count              = var.enable_vpc_flow_logs ? 1 : 0
  name               = "localmart-${var.environment}-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role[0].json
  tags               = local.module_tags
}

data "aws_iam_policy_document" "flow_logs_policy" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups", "logs:DescribeLogStreams"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  count  = var.enable_vpc_flow_logs ? 1 : 0
  name   = "flow-logs-policy"
  role   = aws_iam_role.flow_logs[0].id
  policy = data.aws_iam_policy_document.flow_logs_policy[0].json
}

resource "aws_flow_log" "main" {
  count           = var.enable_vpc_flow_logs ? 1 : 0
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
  tags            = merge(local.module_tags, { Name = "localmart-${var.environment}-flow-log" })
}
