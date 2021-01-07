data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "latestbuilds" {
  name               = "${var.prefix}-latestbuilds"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_policy" "latestbuilds" {
  name = "_${var.prefix}-latestbuilds"
  policy = templatefile("${path.module}/files/policies/latestbuilds_efs.tpl", {
    filesystem_arn   = var.efs_file_system.arn
    access_point_arn = aws_efs_access_point.latestbuilds.arn
    latestbuilds_htpasswd = aws_ssm_parameter.latestbuilds_htpasswd.arn
  })
}

resource "aws_iam_role_policy_attachment" "latestbuilds" {
  role       = var.ecs_iam_role.name
  policy_arn = aws_iam_policy.latestbuilds.arn
}

# todo: remove
resource "aws_iam_instance_profile" "latestbuilds" {
  name = "${var.prefix}-${var.hostname}-latestbuilds"
  role = aws_iam_role.latestbuilds.name
}
