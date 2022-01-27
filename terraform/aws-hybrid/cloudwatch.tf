
resource "aws_cloudwatch_log_group" "go_proxy" {
  name              = "/jenkins/go-proxy"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "maven-cache" {
  name              = "/jenkins/maven-cache"
  retention_in_days = 7
}
