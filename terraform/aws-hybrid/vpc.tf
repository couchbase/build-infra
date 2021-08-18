module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.0.0"

  name = "jenkins-workers"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-2a", "us-east-2b", "us-east-2c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  private_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_vpn_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "jenkins-workers"
    Owner = "build-team"
    Consumer = "jenkins-worker"
  }
}
