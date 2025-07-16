terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "couchbase-terraform-state"
    key            = "prod/restore-testing"
    region         = "us-east-2"
    dynamodb_table = "terraform_state_lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "restore-testing"
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}
