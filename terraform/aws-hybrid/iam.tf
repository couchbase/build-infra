resource "aws_iam_policy" "ecr_pull" {
  name        = "_ecr_pull_allow"
  path        = "/"
  description = "Allow pulling ECR images"

  policy = file("files/iam/policies/ecr-pull.json")
}

module jenkins_worker {
    for_each = toset(var.environments)
    source = "./jenkins_worker"
    environment = each.key
    ecr_pull_policy_arn = aws_iam_policy.ecr_pull.arn
    vpc = module.vpc
}

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "go_proxy" {
  name               = "go-proxy"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role" "ecs" {
  name               = "jenkins-ecs"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec" {
  role       = aws_iam_role.ecs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "maven-cache" {
  name               = "maven-cache"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}
