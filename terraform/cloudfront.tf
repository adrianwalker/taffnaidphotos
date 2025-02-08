resource "aws_cloudfront_distribution" "taffnaidphotos" {
  origin {
    domain_name = aws_s3_bucket.taffnaidphotos.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.taffnaidphotos.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.taffnaidphotos.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["taffnaid.photos"]

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.taffnaidphotos.bucket_regional_domain_name

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.taffnaidphotos.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = "taffnaid.photos"
  }
}

resource "aws_cloudfront_origin_access_identity" "taffnaidphotos" {
  comment = "OAI for taffnaid.photos"
}

data "aws_acm_certificate" "taffnaidphotos" {
  provider = aws.us-east-1
  domain   = "taffnaid.photos"
  statuses = ["ISSUED"]
}

resource "null_resource" "invalidate_cache" {
  triggers = {
    run_id = timestamp()
  }

  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.taffnaidphotos.id} --paths '/*'"
  }
}