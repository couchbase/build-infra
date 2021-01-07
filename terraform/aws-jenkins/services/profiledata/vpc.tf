resource "aws_security_group" "profiledata" {
  name        = "${var.prefix}-profiledata"
  description = "Profiledata"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 4000
    to_port     = 4000
    protocol    = "TCP"
    cidr_blocks = var.private_subnets_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-profiledata"
  }
}
