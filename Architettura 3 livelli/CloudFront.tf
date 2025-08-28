###############################################################################
# CloudFront + Route 53  (ALB frontend us-east-1)
###############################################################################

##############################
# VARIABILI RESTANTI
##############################
variable "cf_alt_domain" {
  description = "CNAME/Alternate domain per CloudFront (es. threetier.<domain>)"
  type        = string
}

##############################
# CLOUDFRONT DISTRIBUTION
##############################
resource "aws_cloudfront_distribution" "frontend_cdn" {
  enabled             = true
  aliases             = ["threetier.${var.domain}"]
  default_root_object = "index.html"
  web_acl_id          = aws_wafv2_web_acl.cf_waf.arn

  # Origin primario (us-east-1)
  origin {
    domain_name = "${var.origin_subdomain}.${var.domain}" # <— origin.threetier.<domain>
    origin_id   = "alb-frontend-primary"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # <— ALB espone solo HTTP
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    connection_attempts = 3
    connection_timeout  = 10
  }

  # Cache behaviour principale (solo metodi safe)
  default_cache_behavior {
    target_origin_id       = "alb-frontend-primary"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cf_cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = { Name = "frontend-cdn" }

  # assicura l'ordine: certificato prima di CF
  depends_on = [aws_acm_certificate_validation.cf_cert]
}

##############################
# Route 53 alias  threetier.<domain>  →  CloudFront
##############################
data "aws_route53_zone" "this" {
  zone_id = "Z01156203MH5V3NVDCNYO" # <-- usa la tua zona pubblica (quella del registrar)
}

resource "aws_route53_record" "cf_alias" {
  zone_id         = data.aws_route53_zone.this.zone_id # <— FIX qui (prima puntava a 'public')
  name            = "threetier"
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.frontend_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.frontend_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
