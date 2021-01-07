output "url" {
  value = var.stopped || var.lb_stopped ? "(disabled)" : "http://${aws_lb.jenkins_master[0].dns_name}"
}

output "master_iam_policy" {
  value = aws_iam_policy.jenkins_master
}

output "efs_access_point" {
  value = aws_efs_access_point.jenkins_home
}

output "master_iam_role" {
  value = aws_iam_role.jenkins_master
}


output "master_security_group" {
  value = aws_security_group.jenkins_master
}

output "worker_security_group" {
  value = aws_security_group.jenkins_worker
}

output "cloud_config_path" {
  value = "/tmp/${var.prefix}-${var.hostname}.cloudconfig"
}
