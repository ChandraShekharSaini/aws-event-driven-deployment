
terraform {
  backend "s3" {
    bucket = "aws-chandra-bucket-890"
    key    = "terraform.tfstate"
    region = "us-east-1"
     use_lockfile ="true"

  }
}