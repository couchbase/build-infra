resource "aws_ssm_parameter" "jenkins_user" {
  name  = "${var.prefix}-${var.jenkins_name}-user"
  type  = "SecureString"
  value = file("~/aws-ssh/jenkins_masters/${var.jenkins_name}/user")
}

resource "aws_ssm_parameter" "jenkins_password" {
  name  = "${var.prefix}-${var.jenkins_name}-password"
  type  = "SecureString"
  value = file("~/aws-ssh/jenkins_masters/${var.jenkins_name}/password")
}
