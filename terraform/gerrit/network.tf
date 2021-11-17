module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  name               = local.project
  cidr               = local.vpc_cidr
  azs                = ["us-east-2a", "us-east-2b"]
  public_subnets     = ["10.0.0.0/24", "10.0.1.0/24"]
  enable_nat_gateway = false
  enable_vpn_gateway = false
}

module "ec2-instance-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.18.0"

  name        = "${local.project}-host-sg"
  description = "Security group for ${local.project} host instance"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "ssh-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "http-8080-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      description = "redirect"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = local.git_port
      to_port     = local.git_port
      protocol    = "tcp"
      description = "${local.project} git port"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_cidr_blocks = [
    "0.0.0.0/0"
  ]
  egress_rules = ["all-tcp"]

  tags = {
    "Owner" = local.owner
  }
}

module "ec2-load-balancer-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.18.0"

  name        = "${local.project}-load-balancer-sg"
  description = "Security group for ${local.project} load balancer"

  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_cidr_blocks = [
    "0.0.0.0/0"
  ]
  egress_rules = ["all-tcp"]

  tags = {
    "Owner" = local.owner
  }
}

module "backup-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.18.0"

  name        = "${local.project}-backup-sg"
  description = "Security group for ${local.project} backups"
  vpc_id      = "vpc-00291041ad30ebce5"

  ingress_with_cidr_blocks = [
    {
      rule        = "ssh-tcp"
      cidr_blocks = var.datacenter_cidr
    },
    {
      rule        = "ssh-tcp"
      cidr_blocks = "3.16.146.0/29"
    }
  ]

  egress_cidr_blocks = [
    "0.0.0.0/0"
  ]
  egress_rules = ["all-tcp"]

  tags = {
    "Owner" = local.owner
  }
}
