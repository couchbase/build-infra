resource "aws_cloudwatch_log_group" "nexus" {
  name              = "/${var.prefix}/nexus"
  retention_in_days = 7
}
