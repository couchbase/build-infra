resource "aws_iam_user" "main" {
  name = "cbd-4108_${var.environment}_jenkins_workers"
  path = "/jenkins/"
}

resource "aws_iam_role" "jenkins_worker" {
  name = "cbd-4108_${var.environment}_jenkins_worker"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_user_policy" "ec2_create" {
  user = aws_iam_user.main.name
  name = "cbd-4108_${var.environment}_ec2_jenkins_create_allow"

  policy = templatefile("${path.module}/files/iam/policies/ec2-create.json", {
      subnet1 = var.vpc.public_subnets[0]
      subnet2 = var.vpc.public_subnets[1]
      subnet3 = var.vpc.public_subnets[2]
      worker_role = aws_iam_role.jenkins_worker.arn
      vpc_arn = var.vpc.vpc_arn
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_pull" {
  role       = aws_iam_role.jenkins_worker.name
  policy_arn = var.ecr_pull_policy_arn
}

resource "aws_iam_instance_profile" "jenkins_worker" {
  name = "cbd-4108_${var.environment}_jenkins_worker"
  role = aws_iam_role.jenkins_worker.name
}

resource "aws_iam_policy" "ssm_read" {
  name        = "cbd-4108_${var.environment}_jenkins_worker_ssm"
  path        = "/"
  description = "Allow pulling secrets for ${var.environment} jenkins workers"

  policy = templatefile("${path.module}/files/iam/policies/ssm-read.json", {
      environment = var.environment
  })
}

resource "aws_iam_role_policy_attachment" "ec2_create" {
  role       = aws_iam_role.jenkins_worker.name
  policy_arn = var.ecr_pull_policy_arn
}

resource "aws_iam_role_policy_attachment" "ssm_read" {
  role       = aws_iam_role.jenkins_worker.name
  policy_arn = aws_iam_policy.ssm_read.arn
}
