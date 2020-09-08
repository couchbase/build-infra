#####################
# ACM Wildcard cert #
#####################

data "aws_acm_certificate" "main" {
  provider    = aws.cert
  domain      = "*.${var.domain}"
  statuses    = ["ISSUED"]
  most_recent = true
}
