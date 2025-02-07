resource "aws_route53_zone" "taffnaidphotos" {
  name = "taffnaid.photos"

  tags = {
    Name = "taffnaid.photos"
  }
}

resource "aws_route53_record" "taffnaidphotos_A" {
  zone_id = aws_route53_zone.taffnaidphotos.zone_id
  name    = "taffnaid.photos"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.taffnaidphotos.domain_name
    zone_id                = aws_cloudfront_distribution.taffnaidphotos.hosted_zone_id
    evaluate_target_health = false
  }
}

output "dns_servers" {
  value = aws_route53_zone.taffnaidphotos.name_servers
}