provider "aws" {
  profile = local.profile
  region  = local.region
  shared_credentials_file = local.shared_credentials_file
}

data "aws_subnet_ids" "public_subnet_ids" {
  vpc_id = local.vpc_id
}

data "aws_caller_identity" "current" {}

terraform {
  backend "s3" {
    bucket = "couchbase-terraform-states"
    key    = "proget/terraform.tfstate"
    region = "us-east-1"
  }
}
