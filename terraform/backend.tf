
terraform {
  backend "s3" {
    bucket = "spring-data-chandra-saini"
    key    = "terraform.tfstate"
    region = "us-east-1"
     use_lockfile ="true"

  }
}