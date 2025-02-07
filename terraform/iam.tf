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