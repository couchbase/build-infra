########
# Live #
########

resource "aws_s3_bucket" "live" {
  bucket = local.url
  acl    = "private"

  logging {
    target_bucket = var.log_buckets.s3
    target_prefix = "${local.url}-access-log-"
  }
}

resource "aws_s3_bucket_object" "live" {
  bucket = aws_s3_bucket.live.bucket
  content_type = "text/html"
  key    = "index.html"
  source = "/dev/null"
}

resource "aws_s3_bucket_policy" "live" {
  bucket = aws_s3_bucket.live.id
  policy = data.aws_iam_policy_document.main.json
}

###########
# Staging #
###########

resource "aws_s3_bucket" "staging" {
  bucket = local.staging_url
  acl    = "private"

  logging {
    target_bucket = var.log_buckets.s3
    target_prefix = "${local.staging_url}-access-log-"
  }
}

resource "aws_s3_bucket_object" "staging" {
  bucket = aws_s3_bucket.staging.bucket
  content_type = "text/html"
  key    = "index.html"
  source = "/dev/null"
}
