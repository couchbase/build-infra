module "backup-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.10.1"

  bucket                  = local.backup_bucket_name
  acl                     = "private"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  lifecycle_rule = [{
    id      = "backups"
    enabled = true

    transition = [{
      days          = 7
      storage_class = "GLACIER"
    }]

    expiration = {
      days = 30
    }
  }]

  versioning = {
    enabled = false
  }
}
