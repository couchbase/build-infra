resource "aws_security_group" "latestbuilds" {
  name        = "${var.prefix}-latestbuilds"
  description = "Latestbuilds"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.private_subnets_cidr_blocks
  }

  ingress {
    description = "HTTP"
    from_port   = 90
    to_port     = 90
    protocol    = "tcp"
    security_groups = [var.bastion_security_group.id, aws_security_group.ui_load_balancer.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.private_subnets_cidr_blocks
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [var.bastion_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-latestbuilds"
  }
}

resource "aws_security_group_rule" "efs" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  source_security_group_id = aws_security_group.latestbuilds.id
  security_group_id = var.efs_security_group.id
}


resource "aws_security_group" "ui_load_balancer" {
  name        = "${var.prefix}-${var.hostname}-ui-load-balancer"
  description = "ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.prefix}-${var.hostname}-ui-load-balancer"
  }
}


resource "aws_security_group_rule" "ui_lb_egress" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ui_load_balancer.id
}
