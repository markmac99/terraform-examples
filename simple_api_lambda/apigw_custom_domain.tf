resource "aws_route53_zone" "themcintyresathome" {
  name          = "themcintyresathome.co.uk"
  comment       = "Hosted zone for themcintyresathome.co.uk"
  force_destroy = false
}


resource "aws_acm_certificate" "apicert" {
  domain_name       = "api.themcintyresathome.co.uk"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "apicert" {
  certificate_arn         = aws_acm_certificate.apicert.arn
  validation_record_fqdns = [for record in aws_route53_record.themcintyresathome_api : record.fqdn]
}

#Route 53 record in the hosted zone to validate the Certificate
resource "aws_route53_record" "themcintyresathome_api" {
  zone_id = aws_route53_zone.themcintyresathome.zone_id
  for_each = {
    for dvo in aws_acm_certificate.apicert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
}

# domain name to be used by APIs 
resource "aws_api_gateway_domain_name" "apigwdomain" {
  regional_certificate_arn = aws_acm_certificate_validation.apicert.certificate_arn
  domain_name              = aws_acm_certificate.apicert.domain_name
}

# DNS entry for the api domain
resource "aws_route53_record" "apidnsentry" {
  name    = aws_api_gateway_domain_name.apigwdomain.domain_name
  type    = "A"
  zone_id = aws_route53_zone.themcintyresathome.id
  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.apigwdomain.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.apigwdomain.regional_zone_id
  }
}

resource "aws_api_gateway_base_path_mapping" "matchapi" {
  api_id      = "mwqyofhckh"
  stage_name  = "stage1"
  domain_name = aws_api_gateway_domain_name.apigwdomain.domain_name
}
