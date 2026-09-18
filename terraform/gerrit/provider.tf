provider "aws" {
  region = "us-east-2"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "couchbase-terraform-state"
    key            = "prod/gerrit"
    region         = "us-east-2"
    dynamodb_table = "terraform_state_lock"
  }
}
