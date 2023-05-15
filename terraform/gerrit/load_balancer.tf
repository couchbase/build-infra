module "alb" {
  source             = "terraform-aws-modules/alb/aws"
  version            = "8.6.0"
  name               = "${local.project}-nlb"
  load_balancer_type = "network"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets

  target_groups = [
    {
      name_prefix      = "ssh-"
      backend_protocol = "TCP"
      backend_port     = 22
      target_type      = "instance"
    },
    {
      name_prefix      = "http-"
      backend_protocol = "TCP"
      backend_port     = local.redirect_port
      # backend_port     = local.web_port
      target_type      = "instance"
    },
    {
      name_prefix      = "git-"
      backend_protocol = "TCP"
      backend_port     = local.git_port
      target_type      = "instance"
    },
    {
     name_prefix      = "https-"
     backend_protocol = "TCP"
     backend_port     = local.web_port
     target_type      = "instance"
    },
  ]

  http_tcp_listeners = [
    {
      port               = 22
      protocol           = "TCP"
      target_group_index = 0
    },
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 1
    },
    {
      port               = local.git_port
      protocol           = "TCP"
      target_group_index = 2
    }
  ]

  https_listeners = [
   {
     port               = 443
     protocol           = "TLS"
     certificate_arn    = "arn:aws:acm:us-east-2:284614897128:certificate/d787ef97-cec6-4d4b-a097-0b35d25b1716"
     target_group_index = 3
   }
  ]

  tags = {
    Environment = "prod"
    Owner       = local.owner
  }
}
