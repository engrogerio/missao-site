# infra/dns/outputs.tf

output "zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "cert_arn" {
  value = aws_acm_certificate_validation.cert.certificate_arn
}

output "name_servers" {
  value = aws_route53_zone.main.name_servers
}