data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "proget" {
  name               = "${var.prefix}-proget"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_instance_profile" "proget" {
  name = "${var.prefix}-proget"
  role = aws_iam_role.proget.name
}

resource "aws_iam_policy" "proget" {
  name = "_${var.prefix}-proget"
  policy = templatefile("${path.module}/files/policies/proget_efs.tpl", {
    filesystem_arn   = var.efs_file_system.arn
    access_point_arn = aws_efs_access_point.proget.arn
  })
}

resource "aws_iam_role_policy_attachment" "proget_ec2" {
  role       = aws_iam_role.proget.name
  policy_arn = aws_iam_policy.proget.arn
}

#attach pre-existing cloudmap policy to proget
resource "aws_iam_role_policy_attachment" "proget_cloudmap" {
  role       = aws_iam_role.proget.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudMapRegisterInstanceAccess"
}
