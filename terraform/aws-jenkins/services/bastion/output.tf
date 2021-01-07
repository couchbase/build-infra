output "iam_role" {
  value = aws_iam_role.bastion
}

output "security_group" {
  value = aws_security_group.bastion
}

output "ssh_cmd" {
  value = var.stopped ? "disabled" : "ssh ec2-user@${aws_instance.bastion[0].public_ip} -i ${var.ssh_key_path}"
}
