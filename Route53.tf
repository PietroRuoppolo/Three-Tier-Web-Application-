locals {
  domain = trimsuffix(var.domain, ".")
}

# Record A -> Alias verso CloudFront
resource "aws_route53_record" "api_primary" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "api.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.frontend_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

##############################
# Output utili
##############################
output "public_zone_id" {
  value = data.aws_route53_zone.this.zone_id
}

output "public_nameservers" {
  value = data.aws_route53_zone.this.name_servers
}

data "aws_route53_zone" "public" {
  zone_id = "Z01156203MH5V3NVDCNYO"
}


# A alias:
resource "aws_route53_record" "origin_alias_to_alb" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "${var.origin_subdomain}.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_lb.frontend_alb.dns_name
    zone_id                = aws_lb.frontend_alb.zone_id
    evaluate_target_health = false
  }
}
# CNAME di validazione ACM 
resource "aws_route53_record" "cf_cert_validation_single" {
  zone_id         = data.aws_route53_zone.public.zone_id
  name            = "_a6234d5ba1e2dadbd987a33b0be4044e.pietroruoppolo.club"
  type            = "CNAME"
  ttl             = 60
  records         = ["_d0e9c8d6257f6502d57cb825f6c17058.xlfgrmvvlj.acm-validations.aws."]
  allow_overwrite = true
}

# CNAME di validazione (dinamico)
resource "aws_route53_record" "alb_origin_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb_origin_cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
    }
  }

  zone_id         = data.aws_route53_zone.public.zone_id
  name            = each.value.name
  type            = "CNAME"
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "alb_origin_cert" {
  provider                = aws.primary
  certificate_arn         = aws_acm_certificate.alb_origin_cert.arn
  validation_record_fqdns = [for r in values(aws_route53_record.alb_origin_cert_validation) : r.fqdn]
}

resource "aws_route53domains_registered_domain" "this" {
  domain_name = "ExampleDomain.club"

  # Nameserver della zona che Terraform gestisce
  name_server {
    name = "ns-128.awsdns-16.com"
  }
  name_server {
    name = "ns-711.awsdns-24.net"
  }
  name_server {
    name = "ns-1389.awsdns-45.org"
  }
  name_server {
    name = "ns-1673.awsdns-17.co.uk"
  }
  lifecycle {
    ignore_changes = [name_server]
  }
}
