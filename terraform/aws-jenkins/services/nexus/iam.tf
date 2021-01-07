data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "nexus" {
  name               = "${var.prefix}-nexus"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_policy" "nexus" {
  name = "_${var.prefix}-nexus"
  policy = templatefile("${path.module}/files/policies/nexus_efs.tpl", {
    filesystem_arn   = var.efs_file_system.arn
    access_point_arn = aws_efs_access_point.nexus.arn
  })
}

resource "aws_iam_role_policy_attachment" "nexus" {
  role       = aws_iam_role.nexus.name
  policy_arn = aws_iam_policy.nexus.arn
}

# todo: remove
resource "aws_iam_instance_profile" "nexus" {
  name = "${var.prefix}-${var.hostname}-nexus"
  role = aws_iam_role.nexus.name
}
