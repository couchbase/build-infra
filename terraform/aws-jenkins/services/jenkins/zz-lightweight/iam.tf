data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "zz_lightweight" {
  name               = "${var.prefix}-${var.jenkins_name}-zz-lightweight"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "zz_lightweight" {
  role       = aws_iam_role.zz_lightweight.id
  policy_arn = aws_iam_policy.zz_lightweight.arn
}

resource "aws_iam_policy" "zz_lightweight" {
  name = "_${var.prefix}-${var.jenkins_name}-zz-lightweight-ssm"

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
          "${aws_ssm_parameter.jenkins_user.arn}",
          "${aws_ssm_parameter.jenkins_password.arn}"
        ]
      }
    ]
}
EOF
}
