output "secret_jenkins_user" {
    value = aws_ssm_parameter.jenkins_user
}

output "secret_jenkins_password" {
    value = aws_ssm_parameter.jenkins_password
}

output "security_group" {
    value = aws_security_group.zz_lightweight
}
