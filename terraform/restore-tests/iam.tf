# IAM resources for restore testing system

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Local values for computed resources
locals {
  account_id = var.aws_account_id != "" ? var.aws_account_id : data.aws_caller_identity.current.account_id
}

# EC2 trust policy for service roles
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# S3 policy for EC2 instances (attached to service roles)
data "aws_iam_policy_document" "ec2_s3_access" {
  statement {
    sid    = "AllowListBuckets"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.backup_buckets.jenkins}",
      "arn:aws:s3:::${var.backup_buckets.gerrit}",
      "arn:aws:s3:::${var.backup_buckets.build_db}"
    ]
  }

  statement {
    sid    = "AllowReadBackups"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${var.backup_buckets.jenkins}/*",
      "arn:aws:s3:::${var.backup_buckets.gerrit}/*",
      "arn:aws:s3:::${var.backup_buckets.build_db}/*"
    ]
  }

  statement {
    sid    = "AllowWriteRestoreResults"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.backup_buckets.jenkins}/restore_testing/*",
      "arn:aws:s3:::${var.backup_buckets.gerrit}/restore_testing/*",
      "arn:aws:s3:::${var.backup_buckets.build_db}/restore_testing/*"
    ]
  }
}

# User policy for launching instances and managing restore tests
data "aws_iam_policy_document" "restore_testing_user" {
  statement {
    sid    = "AllowStatusAndScreenshotReadandDelete"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.backup_buckets.jenkins}/restore_testing/*",
      "arn:aws:s3:::${var.backup_buckets.gerrit}/restore_testing/*",
      "arn:aws:s3:::${var.backup_buckets.build_db}/restore_testing/*"
    ]
  }

  statement {
    sid    = "AllowListBucketsForValidation"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.backup_buckets.jenkins}",
      "arn:aws:s3:::${var.backup_buckets.gerrit}",
      "arn:aws:s3:::${var.backup_buckets.build_db}"
    ]
  }

  statement {
    sid    = "AllowDescribeEC2"
    effect = "Allow"
    actions = [
      "ec2:Describe*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "GetAMIParameter"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [
      "arn:aws:ssm:us-east-2:*:parameter/aws/service/ami-amazon-linux-latest/*"
    ]
  }

  statement {
    sid    = "RunInstance"
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:CreateNetworkInterface",
      "ec2:AttachNetworkInterface"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CreateTags"
    effect = "Allow"
    actions = ["ec2:CreateTags"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["us-east-2"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Owner"
      values   = ["build-team"]
    }
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/Name"
      values   = ["*-restore-testing"]
    }
  }

  statement {
    sid    = "TerminateInstance"
    effect = "Allow"
    actions = [
      "ec2:TerminateInstances"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Owner"
      values   = ["build-team"]
    }
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/Name"
      values   = ["*-restore-testing"]
    }
  }

  statement {
    sid    = "PassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/_jenkins_test_role",
      "arn:aws:iam::${local.account_id}:role/_gerrit_test_role",
      "arn:aws:iam::${local.account_id}:role/_build_db_test_role"
    ]
  }
}

# Service roles for each restore testing service type
resource "aws_iam_role" "jenkins_restore_testing" {
  name               = "_jenkins_test_role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Purpose = "Jenkins restore testing EC2 instances"
    Owner   = "build-team"
  }
}

resource "aws_iam_role" "gerrit_restore_testing" {
  name               = "_gerrit_test_role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Purpose = "Gerrit restore testing EC2 instances"
    Owner   = "build-team"
  }
}

resource "aws_iam_role" "build_db_restore_testing" {
  name               = "_build_db_test_role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Purpose = "Build DB restore testing EC2 instances"
    Owner   = "build-team"
  }
}

# S3 access policy for EC2 instances
resource "aws_iam_policy" "ec2_s3_access" {
  name        = "restore-testing-ec2-s3-access"
  description = "S3 access for restore testing EC2 instances"
  policy      = data.aws_iam_policy_document.ec2_s3_access.json
}

# Attach S3 policy to all service roles
resource "aws_iam_role_policy_attachment" "jenkins_s3_access" {
  role       = aws_iam_role.jenkins_restore_testing.name
  policy_arn = aws_iam_policy.ec2_s3_access.arn
}

resource "aws_iam_role_policy_attachment" "gerrit_s3_access" {
  role       = aws_iam_role.gerrit_restore_testing.name
  policy_arn = aws_iam_policy.ec2_s3_access.arn
}

resource "aws_iam_role_policy_attachment" "build_db_s3_access" {
  role       = aws_iam_role.build_db_restore_testing.name
  policy_arn = aws_iam_policy.ec2_s3_access.arn
}

# Instance profiles for service roles
resource "aws_iam_instance_profile" "jenkins_restore_testing" {
  name = "_jenkins_test_role"
  role = aws_iam_role.jenkins_restore_testing.name
}

resource "aws_iam_instance_profile" "gerrit_restore_testing" {
  name = "_gerrit_test_role"
  role = aws_iam_role.gerrit_restore_testing.name
}

resource "aws_iam_instance_profile" "build_db_restore_testing" {
  name = "_build_db_test_role"
  role = aws_iam_role.build_db_restore_testing.name
}

# IAM user for running restore tests (Jenkins/CI)
resource "aws_iam_user" "restore_testing" {
  name = "restore-testing"

  tags = {
    Purpose = "User for running restore testing jobs"
    Owner   = "build-team"
  }
}

# Policy for restore testing user
resource "aws_iam_policy" "restore_testing_user" {
  name        = "restore-testing-user-policy"
  description = "Policy for restore testing user to launch and manage EC2 instances"
  policy      = data.aws_iam_policy_document.restore_testing_user.json
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "restore_testing_user" {
  user       = aws_iam_user.restore_testing.name
  policy_arn = aws_iam_policy.restore_testing_user.arn
}

# Access key for the user (for Jenkins)
resource "aws_iam_access_key" "restore_testing" {
  user = aws_iam_user.restore_testing.name
}

# Outputs
output "restore_testing_user_name" {
  value = aws_iam_user.restore_testing.name
}

output "restore_testing_access_key_id" {
  value = aws_iam_access_key.restore_testing.id
}

output "restore_testing_secret_access_key" {
  value     = aws_iam_access_key.restore_testing.secret
  sensitive = true
}

output "service_role_arns" {
  value = {
    jenkins  = aws_iam_role.jenkins_restore_testing.arn
    gerrit   = aws_iam_role.gerrit_restore_testing.arn
    build_db = aws_iam_role.build_db_restore_testing.arn
  }
}

output "instance_profile_names" {
  value = {
    jenkins  = aws_iam_instance_profile.jenkins_restore_testing.name
    gerrit   = aws_iam_instance_profile.gerrit_restore_testing.name
    build_db = aws_iam_instance_profile.build_db_restore_testing.name
  }
}
