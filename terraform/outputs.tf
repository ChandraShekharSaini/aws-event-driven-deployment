output "website_url" {
  description = "Website URL"

  value = "http://${aws_instance.web.public_ip}"
}

output "ec2_instance_id" {
  description = "EC2 instance ID"

  value = aws_instance.web.id
}

output "ec2_public_ip" {
  description = "EC2 public IP"

  value = aws_instance.web.public_ip
}

output "s3_bucket" {
  description = "S3 bucket"

  value = aws_s3_bucket.website.bucket
}

output "lambda_function" {
  description = "Lambda function"

  value = aws_lambda_function.deploy.function_name
}

output "github_role_arn" {
  description = "GitHub Actions IAM role ARN"

  value = aws_iam_role.github.arn
}