locals {

  profile = "default"
  region  = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
}

locals {
  name = "proget"
  vpc_id = "vpc-f2b42197"  #default VPC
  cidr_block = ["172.30.0.0/16"]
  #public_subnets = ["172.30.0.0/24", "172.30.1.0/24"]
  cert_arn = "arn:aws:acm:us-east-1:786014483886:certificate/6dc615c5-f1cf-41ae-915c-518561e722a0"
  ec2_subnet = "172.30.1.0/24"
  efs_id = "fs-18c555ed"
  efs_ap = "fsap-0cfd1ddaa7b0beaa3" # "mobile-proget" access point (uid 1000), created outside terraform
  efs_ap_pgsql = "fsap-0ff0ebd0c3d98f4dd" # "mobile-proget-pgsql" access point for /proget-pgsql (uid 101, gid 103)

  # ProGet image tag (proget.inedo.com/productimages/inedo/proget). Pin an exact version.
  # Available tags: curl -s https://proget.inedo.com/v2/productimages/inedo/proget/tags/list
  proget_version = "26.0.14"
  # uid:gid of the "postgres" user inside the ProGet image (checked at boot).
  pg_uid = 101
  pg_gid = 103
  eip_allocation_id = "eipalloc-07606aa1cf0c60cc2" # for EIP 34.231.36.140
  ssh_hosts = ["3.16.146.0/29", "18.206.107.24/29"]
  alarms_email = "build-team@couchbase.com"
}
