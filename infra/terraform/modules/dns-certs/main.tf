terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  module_tags = merge(var.tags, { Module = "dns-certs" })
}

# ─── Public hosted zone ───────────────────────────────────────────────────────
# Expects the domain to already be registered. The zone is looked up by name
# rather than created, so this can be shared across environments.

data "aws_route53_zone" "public" {
  name         = "${var.root_domain}."
  private_zone = false
}

# ─── Private hosted zone ──────────────────────────────────────────────────────

resource "aws_route53_zone" "private" {
  name    = var.internal_domain
  comment = "Private DNS zone for localmart ${var.environment} services."

  vpc {
    vpc_id = var.vpc_id
  }

  # Prevent accidental deletion via terraform destroy
  lifecycle {
    prevent_destroy = false # Set to true in prod after initial apply
  }

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-private-zone" })
}

# ─── ACM wildcard certificate ─────────────────────────────────────────────────
# Covers *.localmart.app and localmart.app.

resource "aws_acm_certificate" "wildcard" {
  domain_name               = var.root_domain
  subject_alternative_names = ["*.${var.root_domain}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.module_tags, { Name = "localmart-${var.environment}-wildcard-cert" })
}

# DNS validation records
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.public.zone_id
}

resource "aws_acm_certificate_validation" "wildcard" {
  certificate_arn         = aws_acm_certificate.wildcard.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
