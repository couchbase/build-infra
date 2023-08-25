provider "aws" {
  region = local.aws_region
}

terraform {
  backend "s3" {
    bucket = "couchbase-ecr-terraform-state"
    key    = "capella-analytics"
    region = "us-east-2"
    dynamodb_table = "terraform_state_lock"
  }
}
