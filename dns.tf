data "aws_route53_zone" "sre_route53_zone" {
  name = var.main_domain_name
}

resource "aws_acm_certificate" "sre_acm_certificate" {
  domain_name       = var.main_domain_name
  validation_method = "DNS"
}

resource "aws_route53_record" "sre_route53_a_record" {
  zone_id = data.aws_route53_zone.sre_route53_zone.zone_id
  name    = var.main_domain_name
  type    = "A"

  alias {
    name                   = aws_lb.sre_lb.dns_name
    zone_id                = aws_lb.sre_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "sre_route53_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.sre_acm_certificate.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.sre_route53_zone.zone_id
}

resource "aws_acm_certificate_validation" "sre_acm_certificate_validation" {
  certificate_arn         = aws_acm_certificate.sre_acm_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.sre_route53_validation_record : record.fqdn]
}

