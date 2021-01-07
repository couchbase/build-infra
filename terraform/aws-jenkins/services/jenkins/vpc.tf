resource "aws_security_group" "jenkins_master" {
  name        = "${var.prefix}-${var.hostname}-master"
  description = "Jenkins master"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.prefix}-${var.hostname}-master"
  }
}

resource "aws_security_group_rule" "master_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jenkins_master.id
}

resource "aws_security_group_rule" "master_lb_http" {
  type                     = "ingress"
  from_port                = var.ui_port
  to_port                  = var.ui_port
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.ui_load_balancer.id
  security_group_id        = aws_security_group.jenkins_master.id
}

resource "aws_security_group_rule" "internal_jnlp" {
  type                     = "ingress"
  from_port                = var.jnlp_port
  to_port                  = var.jnlp_port
  protocol                 = "TCP"
  cidr_blocks              = var.private_subnets_cidr_blocks
  security_group_id        = aws_security_group.jenkins_master.id
}

resource "aws_security_group_rule" "internal_http" {
  type                     = "ingress"
  from_port                = var.ui_port
  to_port                  = var.ui_port
  protocol                 = "TCP"
  cidr_blocks              = var.private_subnets_cidr_blocks
  security_group_id        = aws_security_group.jenkins_master.id
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


###########
# WORKERS #
###########

resource "aws_security_group" "jenkins_worker" {
  name        = "${var.prefix}-${var.hostname}-jenkins-worker"
  description = "Jenkins worker"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.prefix}-${var.hostname}-jenkins-worker"
  }
}

resource "aws_security_group_rule" "worker_jnlp" {
  type                     = "ingress"
  from_port                = var.jnlp_port
  to_port                  = var.jnlp_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.jenkins_master.id
  security_group_id        = aws_security_group.jenkins_worker.id
}

resource "aws_security_group_rule" "worker_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jenkins_worker.id
}


resource "aws_security_group_rule" "efs" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  source_security_group_id = aws_security_group.jenkins_master.id
  security_group_id = var.efs_security_group.id
}
