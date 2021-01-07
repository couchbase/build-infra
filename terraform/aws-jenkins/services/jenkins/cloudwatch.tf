resource "aws_cloudwatch_log_group" "jenkins_master" {
  name              = "/${var.prefix}/${var.hostname}/master"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "jenkins_workers" {
  name              = "/${var.prefix}/${var.hostname}/workers"
  retention_in_days = 7
}
