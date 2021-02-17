resource "aws_security_group" "proget_efs" {
  name        = "${local.name}_efs"
  description = "${local.name} efs"
  vpc_id      = local.vpc_id

  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = local.cidr_block
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.cidr_block
  }

  tags = {
    Name = "${local.name}-lb"
  }
}

resource "aws_security_group" "proget_lb" {
  name        = "${local.name}-lb"
  description = "${local.name} Load Balancer"
  vpc_id      = local.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.cidr_block
  }

  tags = {
    Name = "${local.name}-lb"
  }
}

resource "aws_security_group" "proget" {
  name        = local.name
  description = "${local.name} security group"
  vpc_id      = local.vpc_id

  ingress {
    description = "EFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = local.cidr_block
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.ssh_hosts
  }

  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.proget_lb.id]
  }

  egress {
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.name
  }
}

resource "aws_security_group_rule" "proget" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  description              = "HTTP"
  source_security_group_id = aws_security_group.proget_lb.id
  security_group_id        = aws_security_group.proget.id
}
