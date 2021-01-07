resource "aws_cloudwatch_log_group" "profiledata" {
  name              = "/${var.prefix}/profiledata"
  retention_in_days = 7
}
