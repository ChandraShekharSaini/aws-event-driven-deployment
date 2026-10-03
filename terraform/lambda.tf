data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../lambda/lambda_function.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "deploy" {
  function_name = "${var.project_name}-deploy"

  role = aws_iam_role.lambda.arn

  runtime = "python3.13"
  handler = "lambda_function.lambda_handler"

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  timeout     = 30
  memory_size = 256

  environment {
    variables = {
      INSTANCE_ID = aws_instance.web.id
    }
  }
}

resource "aws_lambda_permission" "s3" {
  statement_id = "AllowS3Invoke"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.deploy.function_name

  principal = "s3.amazonaws.com"

  source_arn = aws_s3_bucket.website.arn
}


resource "aws_s3_bucket_notification" "website" {
  bucket = aws_s3_bucket.website.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.deploy.arn

    events = [
      "s3:ObjectCreated:*"
    ]

    filter_suffix = ".html"
  }

  depends_on = [
    aws_lambda_permission.s3
  ]
}