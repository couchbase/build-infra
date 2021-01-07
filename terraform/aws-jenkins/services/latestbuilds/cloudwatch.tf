resource "aws_cloudwatch_log_group" "latestbuilds" {
  name              = "/${var.prefix}/latestbuilds"
  retention_in_days = 7
}
