locals {
  stopped         = true # if true, does not bring up any instances
  bastion_enabled = false  # enable to create a bastion instance with ssh access for your IP
  lbs_stopped     = false  # don't change this after going live, or we'll need dns updates as lb fqdns will change
  jenkins_stopped = false  # stops all jenkins masters

  # these will take precedence over stopped = false
  server_jenkins_stopped    = true
  cv_jenkins_stopped        = true
  mobile_jenkins_stopped    = true
  analytics_jenkins_stopped = true

  ssh_key_path = "/tmp/aws-migration.pem" # key will be saved here on `terraform apply` if the file doesn't exist

  name           = "migration" # generally appears as a prefix
  region         = "us-east-1"
  private_domain = "couchbase.com"

  cidr            = "10.0.0.0/16"
  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.2.0/23", "10.0.4.0/23"]

  bastion_instance_type = "t2.large"

  ec2_instance_type = "c5ad.4xlarge"
  ec2_max_instances = 16

  # mobile jenkins
  mobile_context         = "EC2"
  mobile_name            = "mobile"
  mobile_subdomain       = "jenkins"
  mobile_image           = "284614897128.dkr.ecr.us-east-1.amazonaws.com/jenkins-master"


  # latestbuilds
  latestbuilds_context   = "EC2"
  latestbuilds_name      = "latestbuilds" #cnt-s231.sc - /data/builds/latestbuilds (also /data/buildteam as buildteam and /data/builds/releases as releases)
  latestbuilds_subdomain = "service"
  latestbuilds_image     = "284614897128.dkr.ecr.us-east-1.amazonaws.com/latestbuilds"
  latestbuilds_cpu       = 1024
  latestbuilds_memory    = 2048

  # nexus
  nexus_context          = "EC2"
  nexus_name             = "nexus"
  nexus_subdomain        = "build"
  nexus_image            = "284614897128.dkr.ecr.us-east-1.amazonaws.com/nexus"
  nexus_cpu              = 1024
  nexus_memory           = 2048

  # proget
  proget_name            = "proget"
  proget_subdomain       = "build"
  proget_ami             = "ami-036e9dea6d267507c"
  proget_instance_type   = "c5a.large"

  # downloads
  downloads_context      = "FARGATE"
  downloads_name         = "downloads"
  downloads_subdomain    = "build"
  downloads_image        = "284614897128.dkr.ecr.us-east-1.amazonaws.com/mobile-util"
  downloads_cpu          = 512
  downloads_memory       = 1024

  # go proxy
  go_proxy_context   = "EC2"
  go_proxy_name      = "goproxy"
  go_proxy_subdomain = "build"
  go_proxy_image     = "gomods/athens:v0.10.0"
  go_proxy_cpu       = 1024
  go_proxy_memory    = 4096

  # maven cache
  maven_cache_context   = "EC2"
  maven_cache_name      = "maven-cache"
  maven_cache_subdomain = "build"
  maven_cache_image     = "284614897128.dkr.ecr.us-east-1.amazonaws.com/archiva:20201214"
  maven_cache_cpu       = 1024
  maven_cache_memory    = 2048

  # profiledata
  profiledata_context   = "EC2"
  profiledata_name      = "profiledata"
  profiledata_subdomain = "build"
  profiledata_image     = "284614897128.dkr.ecr.us-east-1.amazonaws.com/profiledata:20201218"
  profiledata_cpu       = 512
  profiledata_memory    = 1024
}

resource "random_string" "key_file" {
  length  = 16
  special = false
}
