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