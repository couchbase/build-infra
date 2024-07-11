provider "aws" {
  profile = local.profile
  region  = local.region
  shared_credentials_files = local.shared_credentials_files
}

data "aws_subnets" "public_subnet_ids" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

data "aws_caller_identity" "current" {}

terraform {
  backend "s3" {
    bucket = "couchbase-terraform-states"
    key    = "proget/terraform.tfstate"
    region = "us-east-1"
  }
}
