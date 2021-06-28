provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket = "couchbase-terraform-state"
    key    = "prod/jenkins-workers"
    region = "us-east-2"
    dynamodb_table = "terraform_state_lock"
  }
}
