data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  name            = local.name
  cidr            = local.cidr
  azs             = [data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  default_security_group_name = "${local.name}-vpc"

  enable_nat_gateway = local.stopped ? false : true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = local.name
  }
}

# EFS ingress rules are tacked onto this by modules
resource "aws_security_group" "efs" {
  name        = "${local.name}-efs"
  description = "Access to EFS targets"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${local.name}-efs"
  }
}

resource "aws_security_group_rule" "efs-private-subnets-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = module.vpc.private_subnets_cidr_blocks
  security_group_id = aws_security_group.efs.id
}

# Security group for the instances in our ECS cluster
resource "aws_security_group" "ecs_instances" {
  name        = "${local.name}-ecs_instances"
  vpc_id      = module.vpc.vpc_id
  description = "Container Instance Allowed Ports"

  # Unrestricted ingress from private subnets
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }

  # Unrestricted ingress from private subnets
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [module.bastion.security_group.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-ecs_instances"
  }
}
