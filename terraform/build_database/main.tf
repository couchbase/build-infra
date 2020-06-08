terraform {
  backend "s3" {
    bucket = "couchbase-terraform-state"
    key    = "prod/build-db-backup"
    region = "us-east-2"
  }
}

provider "aws" {
  region = "us-east-2"
}

# Programmatic-only user has been created in advance, access key and secret are stored in lastpass
data "aws_iam_user" "main" {
  user_name = "backups.build-db"
}

resource "aws_s3_bucket" "main" {
  bucket = "build-db.backups"
  acl    = "private"

  lifecycle_rule {
    enabled = true
    transition {
      days          = 14
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }

  tags = {
    Name        = "build-db backups bucket"
    Owner       = "Build Team"
    Environment = "prod"
  }
}

resource "aws_iam_user_policy" "main" {
  name = "_s3_${aws_s3_bucket.main.bucket}_rw"
  user = data.aws_iam_user.main.user_name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:DeleteObject",
                "s3:DeleteObjectVersion",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:GetObjectVersion",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:ListBucketVersions",
                "s3:ListMultipartUploadParts",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.main.bucket}",
                "arn:aws:s3:::${aws_s3_bucket.main.bucket}/*"
            ]
        }
    ]
}
POLICY
}
