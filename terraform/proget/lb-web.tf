resource "aws_lb_target_group" "proget" {
  name        = "${local.name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id = local.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    enabled = true
    path = "/feeds/dev"
    port = 80
    protocol = "HTTP"
    interval = 30
    healthy_threshold = 10
    unhealthy_threshold = 10
    timeout = 15
    matcher = "200"
  }
}

resource "aws_lb" "proget" {
  name               = local.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.proget_lb.id ]
  subnets            = data.aws_subnet_ids.public_subnet_ids.ids


  enable_deletion_protection = false
}

resource "aws_lb_listener" "proget_https" {
  load_balancer_arn = aws_lb.proget.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = local.cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.proget.arn
  }
}

resource "aws_lb_listener" "proget_http" {
  load_balancer_arn = aws_lb.proget.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
