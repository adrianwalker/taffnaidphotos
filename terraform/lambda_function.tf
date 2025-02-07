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

data "archive_file" "taffnaidphotos" {
  type        = "zip"
  output_path = "/tmp/taffnaidphotos.zip"
  source_dir  = "${path.module}/../lambda"
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