provider "aws" {
  region = "eu-west-2"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "archive" {}

resource "aws_s3_bucket" "taffnaidphotos" {
  bucket = "taffnaid.photos"

  tags = {
    Name = "taffnaid.photos"
  }
}

resource "aws_s3_bucket_public_access_block" "taffnaidphotos" {
  bucket = aws_s3_bucket.taffnaidphotos.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "taffnaidphotos" {
  bucket = aws_s3_bucket.taffnaidphotos.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

resource "aws_cloudfront_origin_access_identity" "taffnaidphotos" {
  comment = "OAI for taffnaid.photos"
}

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

resource "aws_s3_object" "taffnaidphotos_404" {
  bucket       = aws_s3_bucket.taffnaidphotos.bucket
  key          = "404.html"
  content_type = "text/html"
  source       = "${path.module}/../web/404.html"
  etag = filemd5("${path.module}/../web/404.html")

  tags = {
    Name = "taffnaid.photos"
  }
}

resource "aws_s3_object" "taffnaidphotos_album" {
  bucket       = aws_s3_bucket.taffnaidphotos.bucket
  key          = "album.png"
  content_type = "image/png"
  source       = "${path.module}/../web/album.png"
  etag = filemd5("${path.module}/../web/album.png")

  tags = {
    Name = "taffnaid.photos"
  }
}

resource "aws_s3_object" "taffnaidphotos_robots" {
  bucket       = aws_s3_bucket.taffnaidphotos.bucket
  key          = "robots.txt"
  content_type = "text/plain"
  source       = "${path.module}/../web/robots.txt"
  etag = filemd5("${path.module}/../web/robots.txt")

  tags = {
    Name = "taffnaid.photos"
  }
}

resource "aws_s3_object" "taffnaidphotos_css" {
  bucket       = aws_s3_bucket.taffnaidphotos.bucket
  key          = "taffnaidphotos.css"
  content_type = "text/css"
  source       = "${path.module}/../web/taffnaidphotos.css"
  etag = filemd5("${path.module}/../web/taffnaidphotos.css")

  tags = {
    Name = "taffnaid.photos"
  }
}

resource "aws_s3_object" "taffnaidphotos_js" {
  bucket       = aws_s3_bucket.taffnaidphotos.bucket
  key          = "taffnaidphotos.js"
  content_type = "text/javascript"
  source       = "${path.module}/../web/taffnaidphotos.js"
  etag = filemd5("${path.module}/../web/taffnaidphotos.js")

  tags = {
    Name = "taffnaid.photos"
  }
}

data "aws_acm_certificate" "taffnaidphotos" {
  provider = aws.us-east-1
  domain   = "taffnaid.photos"
  statuses = ["ISSUED"]
}

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

resource "aws_iam_role" "taffnaidphotos" {
  name = "taffnaid.photos"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "taffnaid.photos"
  }
}

resource "aws_iam_role_policy" "taffnaidphotos" {
  name = "taffnaid.photos"
  role = aws_iam_role.taffnaidphotos.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::taffnaid.photos",
          "arn:aws:s3:::taffnaid.photos/*"
        ]
      }
    ]
  })
}

data "archive_file" "taffnaidphotos" {
  type        = "zip"
  output_path = "/tmp/taffnaidphotos.zip"
  source_dir  = "${path.module}/../lambda"
}

resource "aws_lambda_function" "taffnaidphotos" {

  depends_on = [data.archive_file.taffnaidphotos]

  function_name = "taffnaidphotos"
  handler       = "taffnaidphotos.handler"
  runtime       = "python3.11"
  role          = aws_iam_role.taffnaidphotos.arn

  filename         = data.archive_file.taffnaidphotos.output_path
  source_code_hash = data.archive_file.taffnaidphotos.output_base64sha256

  timeout = 900

  environment {
    variables = {
      BUCKET = aws_s3_bucket.taffnaidphotos.bucket
    }
  }

  layers = [
    aws_serverlessapplicationrepository_cloudformation_stack.image_magick_layer.outputs["LayerVersion"]
  ]

  tags = {
    Name = "taffnaid.photos"
  }
}

resource "aws_serverlessapplicationrepository_cloudformation_stack" "image_magick_layer" {
  name           = "image-magick-lambda-layer"
  application_id = "arn:aws:serverlessrepo:us-east-1:145266761615:applications/image-magick-lambda-layer"

  semantic_version = "1.0.0"
  capabilities = ["CAPABILITY_IAM"]

  tags = {
    Name = "taffnaid.photos"
  }
}

resource "null_resource" "invalidate_cache" {
  triggers = {
    run_id = timestamp()
  }

  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.taffnaidphotos.id} --paths '/*'"
  }
}

output "dns_servers" {
  value = aws_route53_zone.taffnaidphotos.name_servers
}
