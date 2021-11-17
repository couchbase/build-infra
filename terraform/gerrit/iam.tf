data "aws_iam_policy_document" "ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "gerrit" {
  name               = local.project
  assume_role_policy = data.aws_iam_policy_document.ec2.json
}

resource "aws_iam_instance_profile" "gerrit" {
  name = local.project
  role = aws_iam_role.gerrit.name
}

resource "aws_iam_policy" "cloudwatch" {
  name   = "${local.project}-cloudwatch"
  policy = file("./files/iam_cloudwatch.json")
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.gerrit.name
  policy_arn = aws_iam_policy.cloudwatch.arn
}

resource "aws_iam_policy" "s3_backups_rw" {
  name   = "${local.project}-s3-backups_RW"
  policy = file("./files/iam_s3_backups_rw.json")
}


resource "aws_iam_policy" "backups_sns_publish" {
  name   = "${local.project}-backups-sns-publish"
  policy = templatefile("./files/iam_sns_publish.json", {
    sns_topic_arn = aws_sns_topic.backups.arn
  })
}

resource "aws_iam_role_policy_attachment" "sns_publish" {
  role       = aws_iam_role.gerrit.name
  policy_arn = aws_iam_policy.backups_sns_publish.arn
}

resource "aws_iam_policy" "ec2" {
  name   = "${local.project}-ec2"
  policy = file("./files/iam_ec2.json")
}

resource "aws_iam_role_policy_attachment" "s3_backups_read" {
  role       = aws_iam_role.gerrit.name
  policy_arn = aws_iam_policy.s3_backups_rw.arn
}

resource "aws_iam_role_policy_attachment" "ec2" {
  role       = aws_iam_role.gerrit.name
  policy_arn = aws_iam_policy.ec2.arn
}

resource "aws_iam_policy" "ssm" {
  name        = "${local.project}-ssm"
  path        = "/"
  description = "Allow pulling secrets for ${local.project}"

  policy = file("${path.module}/files/ssm-read.json")
}

resource "aws_iam_role_policy_attachment" "ssm_read" {
  role       = aws_iam_role.gerrit.name
  policy_arn = aws_iam_policy.ssm.arn
}

# Backups

resource "aws_iam_role" "backup" {
  name               = "${local.project}-backup"
  assume_role_policy = data.aws_iam_policy_document.ec2.json
}

resource "aws_iam_instance_profile" "backup" {
  name = "${local.project}-backup"
  role = aws_iam_role.backup.name
}

resource "aws_iam_policy" "backup" {
  name   = "${local.project}-backup"
  policy = templatefile("./files/iam_backups.json.tpl", {
    bucket = local.backup_bucket_name
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = aws_iam_policy.backup.arn
}

resource "aws_iam_policy" "backup-passrole" {
  name   = "${local.project}-backup-passrole"
  policy = templatefile("./files/iam_backups_passrole.json.tpl", {
      account_id = data.aws_caller_identity.current.account_id
  })
}

resource "aws_iam_user_policy_attachment" "backup-passrole" {
  user       = "cbd-4108_server_jenkins_workers"
  policy_arn = aws_iam_policy.backup-passrole.arn
}
