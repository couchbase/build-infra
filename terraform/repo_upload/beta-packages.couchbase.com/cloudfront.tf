###################
# Access Identity #
###################

resource "aws_cloudfront_origin_access_identity" "main" {
    comment = "access-id-${local.url}"
}


################
# Distribution #
################

resource "aws_cloudfront_distribution" "main" {
  aliases         = [local.url]
  enabled         = true
  is_ipv6_enabled = true
  price_class     = var.cloudfront_price_class

  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_cloudfront_origin_access_identity.main.comment

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
  }

  origin {
    domain_name = aws_s3_bucket.live.bucket_regional_domain_name
    origin_id   = aws_cloudfront_origin_access_identity.main.comment

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations        = var.geo_restriction_blacklist
    }
  }

  viewer_certificate {
      acm_certificate_arn      = data.aws_acm_certificate.main.arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1"
  }

  logging_config {
    include_cookies = false
    bucket          = "${var.log_buckets.cloudfront}.s3.amazonaws.com"
    prefix          = "${var.subdomain}-access/"
  }
}