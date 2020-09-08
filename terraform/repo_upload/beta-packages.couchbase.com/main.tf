#########
# State #
#########

terraform {
  backend "s3" {
    bucket = "cb-terraform-state-store"
    key    = "build-team/repo_upload/beta-packages.tfstate"
    region = "us-east-2"
  }
}

#############
# Providers #
#############

provider "aws" {
  alias  = "cert"
  region = "us-east-1"
}

provider "aws" {
  region = "us-east-1" # Note: cross location s3 logging is disallowed, this must match the log bucket region
}


##########
# Locals #
##########

locals {
  url = "${var.subdomain}.${var.domain}"
  staging_url = "${var.subdomain}-staging.${var.domain}"
}
