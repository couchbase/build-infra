resource "aws_ssm_parameter" "latestbuilds_htpasswd" {
  name  = "${var.prefix}-latestbuilds-htpasswd"
  type  = "SecureString"
  value = file("~/aws-ssh/latestbuilds/htpasswd")
}
