#################
# Bucket policy #
#################

data "aws_iam_policy_document" "main" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.live.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
    }
  }
  statement {
    actions = ["s3:GetObject"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
    }
    resources = ["${aws_s3_bucket.live.arn}/*"]
  }
}
