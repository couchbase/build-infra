module "capella_analytics_ecr" {
  source = "./modules/ecr"
  for_each = toset(local.repositories)

  ecr_repo_name          = each.value
  aws_region             = local.aws_region
  ecr_image_scan         = local.ecr_image_scan
  ecr_image_age          = var.ecr_image_age
  whitelist_ips          = local.couchbase_ips
  pull_arns              = local.repo_pull_access_arns
  push_arns              = local.repo_push_access_arns
  push_roles             = local.repo_push_access_roles
}
