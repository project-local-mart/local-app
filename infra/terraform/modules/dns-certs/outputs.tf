output "public_zone_id" {
  description = "Route53 public hosted zone ID."
  value       = data.aws_route53_zone.public.zone_id
}

output "public_zone_name" {
  description = "Route53 public hosted zone name."
  value       = data.aws_route53_zone.public.name
}

output "private_zone_id" {
  description = "Route53 private hosted zone ID."
  value       = aws_route53_zone.private.zone_id
}

output "private_zone_name" {
  description = "Route53 private hosted zone name."
  value       = aws_route53_zone.private.name
}

output "acm_cert_arn" {
  description = "Validated ACM wildcard certificate ARN."
  value       = aws_acm_certificate_validation.wildcard.certificate_arn
}

output "acm_cert_status" {
  description = "ACM certificate status — should be ISSUED after apply."
  value       = aws_acm_certificate.wildcard.status
}
