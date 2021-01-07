data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_ecs" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com",
        "ec2.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "ecs" {
  name               = "${local.name}-ecs"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec" {
  role       = aws_iam_role.ecs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_runner" {
  name               = "${local.name}-ecs-task-runner"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_policy" "ecs_task_runner" {
  name = "${local.name}-ecs-task-runner"

  policy = templatefile("files/policies/ecs_task_runner.tpl", {
    roles       = "[${join(",", formatlist("\"%s\"", [aws_iam_role.ecs.arn, aws_iam_role.ec2_ecs.arn]))}]"
    cluster_arn = aws_ecs_cluster.main.arn
    region      = local.region
    account     = data.aws_caller_identity.current.account_id
  })
}

resource "aws_iam_role" "ec2_ecs" {
  name               = "${local.name}-ec2-ecs"
  assume_role_policy = data.aws_iam_policy_document.ec2_ecs.json
}

resource "aws_iam_role_policy_attachment" "ec2_ecs" {
  role       = aws_iam_role.ec2_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ec2_ecs" {
  name = "${local.name}-ec2-ecs"
  role = aws_iam_role.ec2_ecs.name
}
