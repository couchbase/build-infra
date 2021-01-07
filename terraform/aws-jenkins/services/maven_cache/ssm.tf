resource "aws_ssm_parameter" "archiva_password" {
  name  = "${var.prefix}-archiva_password"
  type  = "SecureString"
  value = trimspace(file("~/aws-ssh/archiva_password"))
}
