provider "aws" {
  region = local.region
}

data "aws_caller_identity" "current" {}

terraform {
  backend "s3" {
    bucket = "couchbase-terraform-state"
    key    = "prod/jenkins-aws"
    region = "us-east-2"
    dynamodb_table = "terraform_state_lock"
  }
}
