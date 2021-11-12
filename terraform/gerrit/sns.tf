resource "aws_sns_topic" "backups" {
  name = "${local.project}-backups"
}

resource "aws_sns_topic_subscription" "main" {
  topic_arn = aws_sns_topic.backups.arn
  protocol  = "email"
  endpoint  = local.alert_email_recipient
}
