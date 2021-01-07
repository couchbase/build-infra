resource "aws_security_group" "bastion" {
  name        = "${var.prefix}-bastion"
  description = "Bastion access"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.prefix}-bastion"
  }
}

resource "aws_security_group_rule" "bastion_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "efs" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id = var.efs_security_group.id
}
