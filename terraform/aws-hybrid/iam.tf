resource "aws_iam_policy" "ecr_pull" {
  name        = "_ecr_pull_allow"
  path        = "/"
  description = "Allow pulling ECR images"

  policy = file("files/iam/policies/ecr-pull.json")
}

module jenkins_worker {
    for_each = toset( ["analytics", "cv", "server"] )
    source = "./jenkins_worker"
    environment = each.key
    ecr_pull_policy_arn = aws_iam_policy.ecr_pull.arn
    vpc = module.vpc
}
