data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "s3_backups_read" {
  name   = "_${var.prefix}-s3-backups_RO"
  policy = file("${path.module}/files/policies/s3_backups_read.tpl")
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.prefix}-bastion"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_role" "bastion" {
  name               = "${var.prefix}-bastion"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "bastion_server_jenkins_efs" {
  role       = aws_iam_role.bastion.name
  policy_arn = var.server_jenkins_iam_policy.arn
}

resource "aws_iam_role_policy_attachment" "bastion_cv_jenkins_efs" {
  role       = aws_iam_role.bastion.name
  policy_arn = var.cv_jenkins_iam_policy.arn
}

resource "aws_iam_role_policy_attachment" "bastion_s3_backups_RO" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.s3_backups_read.arn
}
