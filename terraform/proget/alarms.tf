resource "aws_sns_topic" "alarm" {
  name = "proget-alarms"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF

  provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${local.alarms_email}"
  }
}

# Typically, autoscaling group should provision a new node if one goes down.
# Thus, we don't want to check too often.
# Checks every 5 min.  If healthy host < 1 for 3 consecutive times, then something is likely wrong.
resource "aws_cloudwatch_metric_alarm" "lb_healthyhost" {
  alarm_name          = "Proget_Healthy_Host_Alarm"
  comparison_operator = "LessThanThreshold"
  datapoints_to_alarm = 3
  evaluation_periods  = "3"
  period              = "300"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Number of healthy nodes in Target Group"
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.alarm.arn]
  dimensions = {
    TargetGroup  = aws_lb_target_group.proget.arn_suffix
    LoadBalancer = aws_lb.proget.arn_suffix
  }
}
