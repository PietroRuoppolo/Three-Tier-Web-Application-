variable "domain" {
  description = "Root domain managed in Route53"
  type        = string
  default     = "pietroruoppolo.club"
}

# 1) Richiesta certificato (root + wildcard) in us-east-1
resource "aws_acm_certificate" "cf_cert" {
  provider                  = aws.useast1
  domain_name               = var.domain
  subject_alternative_names = ["*.${var.domain}"]
  validation_method         = "DNS"
  lifecycle { create_before_destroy = true }
}

# Local: mappa per i record di validazione
locals {
  cert_domains = toset([var.domain, "*.${var.domain}"])
  dvo_by_domain = {
    for dvo in aws_acm_certificate.cf_cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
}

# 2) Record DNS di validazione
resource "aws_route53_record" "cf_cert_validation" {
  for_each = { for d in local.cert_domains : d => local.dvo_by_domain[d] }

  zone_id         = aws_route53_zone.public.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}

# 3) Validazione certificato
resource "aws_acm_certificate_validation" "cf_cert" {
  provider                = aws.useast1
  certificate_arn         = aws_acm_certificate.cf_cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cf_cert_validation : r.fqdn]
  timeouts { create = "150m" }
}

# Output (ALB riutilizzabile SOLO se in us-east-1)
output "backend_cert_arn" {
  description = "ARN del certificato ACM us-east-1 (wildcard). Usalo per ALB solo se l'ALB è in us-east-1."
  value       = aws_acm_certificate_validation.cf_cert.certificate_arn
}


resource "aws_acm_certificate" "alb_origin_cert" {
  provider          = aws.primary
  domain_name       = "origin.threetier.pietroruoppolo.club"
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
}


