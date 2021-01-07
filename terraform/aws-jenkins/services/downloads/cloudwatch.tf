resource "aws_cloudwatch_log_group" "downloads" {
  name              = "/${var.prefix}/downloads"
  retention_in_days = 7
}
