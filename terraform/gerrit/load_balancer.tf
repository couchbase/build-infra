module "alb" {
  source             = "terraform-aws-modules/alb/aws"
  version            = "9.9.0"
  name               = "${local.project}-nlb"
  load_balancer_type = "network"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets

  enable_cross_zone_load_balancing = true
  enable_deletion_protection = true
  create_security_group = false

  target_groups = {
    gerrit-git = {
      name_prefix       = "git-"
      protocol          = "TCP"
      port              = local.git_port
      target_type       = "instance"
      create_attachment = false
    },
    gerrit-http = {
      name_prefix       = "http-"
      protocol          = "TCP"
      port              = local.redirect_port
      target_type       = "instance"
      create_attachment = false
    },
    gerrit-https = {
      name_prefix       = "https-"
      protocol          = "TCP"
      port              = local.web_port
      target_type       = "instance"
      create_attachment = false
    },
  }

  listeners = {
    git = {
      port               = 29418
      protocol           = "TCP"
      forward = {
        target_group_key = "gerrit-git"
      }
    },
    http = {
      port               = 80
      protocol           = "TCP"
      forward = {
        target_group_key = "gerrit-http"
      }
    },
    https = {
      port               = 443
      protocol           = "TLS"
      certificate_arn    = "arn:aws:acm:us-east-2:284614897128:certificate/53752f47-50ca-4d79-a7c1-8351948cbc4f"
      ssl_policy         = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      forward = {
        target_group_key = "gerrit-https"
      }
    }
  }

  tags = {
    Name        = "${local.project}-nlb"
    Environment = "prod"
    Owner       = local.owner
  }
}
