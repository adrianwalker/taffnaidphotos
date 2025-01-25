provider "aws" {
  region = "eu-west-2"
}

# S3 Bucket
resource "aws_s3_bucket" "taffnaid_photos" {
  bucket = "taffnaid.photos"

  tags = {
    Name = "taffnaid.photos"
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "taffnaid_photos" {
  bucket = aws_s3_bucket.taffnaid_photos.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "taffnaid_photos" {
  bucket = aws_s3_bucket.taffnaid_photos.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

# CloudFront Origin Access Identity (OAI)
resource "aws_cloudfront_origin_access_identity" "taffnaid_photos" {
  comment = "OAI for taffnaid.photos"
}

# S3 Bucket Policy for OAI
resource "aws_s3_bucket_policy" "taffnaid_photos" {
  bucket = aws_s3_bucket.taffnaid_photos.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.taffnaid_photos.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.taffnaid_photos.arn}/*"
      }
    ]
  })
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "taffnaid_photos" {
  origin {
    domain_name = aws_s3_bucket.taffnaid_photos.bucket_regional_domain_name # Use the REST API endpoint
    origin_id   = aws_s3_bucket.taffnaid_photos.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.taffnaid_photos.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["taffnaid.photos"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.taffnaid_photos.bucket_regional_domain_name

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600  # 1 hour
    max_ttl     = 86400 # 1 day
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:590183793273:certificate/3c74778b-38bd-48ef-8675-660f25078963"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# Route 53 Hosted Zone
resource "aws_route53_zone" "taffnaid_photos" {
  name = "taffnaid.photos"

  tags = {
    Name = "taffnaid.photos"
  }
}

# Route 53 A Record (IPv4)
resource "aws_route53_record" "taffnaid_photos_A" {
  zone_id = aws_route53_zone.taffnaid_photos.zone_id
  name    = "taffnaid.photos"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.taffnaid_photos.domain_name
    zone_id                = aws_cloudfront_distribution.taffnaid_photos.hosted_zone_id
    evaluate_target_health = false
  }
}

# Route 53 AAAA Record (IPv6)
resource "aws_route53_record" "taffnaid_photos_AAAA" {
  zone_id = aws_route53_zone.taffnaid_photos.zone_id
  name    = "taffnaid.photos"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.taffnaid_photos.domain_name
    zone_id                = aws_cloudfront_distribution.taffnaid_photos.hosted_zone_id
    evaluate_target_health = false
  }
}