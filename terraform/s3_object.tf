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