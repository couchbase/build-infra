locals {

  profile = "default"
  region  = "us-east-1"
  shared_credentials_file = "~/.aws/credentials"
}

locals {
  name = "proget"
  vpc_id = "vpc-f2b42197"  #default VPC
  cidr_block = ["172.30.0.0/16"]
  #public_subnets = ["172.30.0.0/24", "172.30.1.0/24"]
  cert_arn = "arn:aws:acm:us-east-1:786014483886:certificate/6dc615c5-f1cf-41ae-915c-518561e722a0"
  ec2_subnet = "172.30.1.0/24"
  ami_id = "ami-01accb82117ea785e"
  eip_allocation_id = "eipalloc-07606aa1cf0c60cc2" # for EIP 34.231.36.140
  ssh_hosts = ["67.180.86.220/32"]
  alarms_email = "build-team@couchbase.com"
}
