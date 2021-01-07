data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "downloads" {
  name               = "${var.prefix}-downloads"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_policy" "downloads" {
  name = "_${var.prefix}-downloads"
  policy = templatefile("${path.module}/files/policies/downloads_efs.tpl", {
    filesystem_arn   = var.efs_file_system.arn
    access_point_arn = aws_efs_access_point.downloads.arn
  })
}

resource "aws_iam_role_policy_attachment" "downloads" {
  role       = aws_iam_role.downloads.name
  policy_arn = aws_iam_policy.downloads.arn
}

# todo: remove
resource "aws_iam_instance_profile" "downloads" {
  name = "${var.prefix}-${var.hostname}-downloads"
  role = aws_iam_role.downloads.name
}
