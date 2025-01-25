# Default provider for eu-west-2
provider "aws" {
  region = "eu-west-2"
}

# Second provider for us-east-1 (required for ACM certificates used by CloudFront)
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# S3 Bucket for hosting the website
resource "aws_s3_bucket" "taffnaidphotos" {
  bucket = "taffnaid.photos"

  tags = {
    Name = "taffnaid.photos"
  }
}

# Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "taffnaidphotos" {
  bucket = aws_s3_bucket.taffnaidphotos.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configure the S3 bucket as a static website
resource "aws_s3_bucket_website_configuration" "taffnaidphotos" {
  bucket = aws_s3_bucket.taffnaidphotos.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

# CloudFront Origin Access Identity (OAI) for secure access to S3
resource "aws_cloudfront_origin_access_identity" "taffnaidphotos" {
  comment = "OAI for taffnaid.photos"
}

# S3 Bucket Policy to allow access only via CloudFront
resource "aws_s3_bucket_policy" "taffnaidphotos" {
  bucket = aws_s3_bucket.taffnaidphotos.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.taffnaidphotos.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.taffnaidphotos.arn}/*"
      }
    ]
  })
}

# Import existing ACM certificate in us-east-1
data "aws_acm_certificate" "taffnaidphotos" {
  provider = aws.us-east-1
  domain   = "taffnaid.photos"
  statuses = ["ISSUED"]
}

# CloudFront Distribution
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
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
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

# Route 53 Hosted Zone
resource "aws_route53_zone" "taffnaidphotos" {
  name = "taffnaid.photos"

  tags = {
    Name = "taffnaid.photos"
  }
}

# Route 53 A Record for CloudFront (IPv4)
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

# Output the certificate ARN for verification
output "certificate_arn" {
  value = data.aws_acm_certificate.taffnaidphotos.arn
}

# Output the DNS servers for the Route 53 hosted zone
output "dns_servers" {
  value = aws_route53_zone.taffnaidphotos.name_servers
}
