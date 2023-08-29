data "aws_caller_identity" "current" {}

locals {
  repositories = ["capella-analytics", "goldfish-nebula"]
  aws_region             = "us-east-2"
  ecr_image_scan         = true
  # Populate IPs that should be given access to
  # before running terraform
  couchbase_ips          = [
    "xx.xxx.xxx.xx/29"
  ]

  # Populate AWS accounts that should be granted access first by adding
  # "arn:aws:iam::xxxxxxxxxxxx:root"
  repo_pull_access_arns  = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
  ]
  repo_push_access_arns  = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
  repo_push_access_roles = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/cbd-4108_server_jenkins_worker"]
}
