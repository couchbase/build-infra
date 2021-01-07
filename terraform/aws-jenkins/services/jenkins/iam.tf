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

##########
# MASTER #
##########

resource "aws_iam_role" "jenkins_master" {
  name               = "${var.prefix}-${var.hostname}-master"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_policy" "jenkins_master" {
  name = "_${var.prefix}-${var.hostname}-master"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Resource": "${var.efs_file_system.arn}",
            "Condition": {
                "StringEquals": {
                    "elasticfilesystem:AccessPointArn": "${aws_efs_access_point.jenkins_home.arn}"
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "jenkins_master" {
  role       = aws_iam_role.jenkins_master.name
  policy_arn = aws_iam_policy.jenkins_master.arn
}

resource "aws_iam_role_policy_attachment" "jenkins_master_ecs_taskrunner" {
  role       = aws_iam_role.jenkins_master.name
  policy_arn = var.ecs_task_runner_arn
}

resource "aws_iam_instance_profile" "jenkins_master" {
  name = "${var.prefix}-${var.hostname}-master"
  role = aws_iam_role.jenkins_master.name
}

##########
# WORKER #
##########

resource "aws_iam_role" "worker_ecs" {
  name               = "${var.prefix}-${var.hostname}-worker-ecs"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "worker_ecs_task_exec" {
  role       = aws_iam_role.worker_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "jenkins_worker_ssm" {
  role       = var.ecs_role.name
  policy_arn = aws_iam_policy.worker_ssm.arn
}

resource "aws_iam_policy" "worker_ssm" {
  name = "_${var.prefix}-${var.hostname}-worker-ssm"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "secretsmanager:GetSecretValue"
        ],
        "Resource": [
          "${var.profiledata_key.arn}",
          "${module.zz_lightweight.secret_jenkins_user.arn}",
          "${module.zz_lightweight.secret_jenkins_password.arn}"
        ]
      }
    ]
}
EOF
}
