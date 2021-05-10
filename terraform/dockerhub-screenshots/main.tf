terraform {
  backend "s3" {
    bucket = "cb-terraform-state-store"
    key    = "build-team/dockerhub/screenshot-hosting.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {
  region = "us-east-2"
}

module "cloudfront-s3-cdn" {
  source  = "cloudposse/cloudfront-s3-cdn/aws"
  version = "0.62.0"

  namespace                          = "cb"
  stage                              = "dockerhub"
  name                               = "screenshots"
  logging_enabled                    = false
  block_origin_public_access_enabled = true
}
