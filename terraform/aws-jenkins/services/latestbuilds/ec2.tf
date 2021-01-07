resource "aws_lb_target_group" "latestbuilds" {
  name        = "${var.prefix}-${var.hostname}-web"
  port        = 90
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    enabled             = true
    path                = "/"
    port                = var.ui_port
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 10
    unhealthy_threshold = 10
    timeout             = 15
    matcher             = "200,401,403" # 401 or 403 is normal when not logged in
  }
}

resource "aws_lb" "latestbuilds" {
  count = var.lb_stopped ? 0 : 1
  name               = "${var.prefix}-${var.hostname}-ui"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ui_load_balancer.id]
  subnets            = var.public_subnets

  enable_deletion_protection = false
}

resource "aws_lb_listener" "latestbuilds" {
  count = var.lb_stopped ? 0 : 1
  load_balancer_arn = aws_lb.latestbuilds[0].arn

  port     = "80"
  protocol = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.latestbuilds.arn
  }
}

resource "aws_lb_listener_rule" "latestbuilds" {
  count = var.lb_stopped ? 0 : 1
  listener_arn = aws_lb_listener.latestbuilds[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.latestbuilds.arn
  }

  condition {
    host_header {
      values = [
        "*.amazonaws.com",
        "latestbuilds.service.couchbase.com"
      ]
    }
  }
}
