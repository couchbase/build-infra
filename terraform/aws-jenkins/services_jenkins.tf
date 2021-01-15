locals {
  domain = "couchbase.com"

  jenkins_image     = "284614897128.dkr.ecr.us-east-1.amazonaws.com/jenkins:lts"

  # server.jenkins.couchbase.com
  server_cpu       = 2048
  server_memory    = 4096
  server_ui_port   = 8080
  server_jnlp_port = 50002

  # cv.jenkins.couchbase.com
  cv_cpu       = 2048
  cv_memory    = 4096
  cv_ui_port   = 8080
  cv_jnlp_port = 50002

  # analytics.jenkins.couchbase.com
  analytics_cpu       = 2048
  analytics_memory    = 4096
  analytics_ui_port   = 8080
  analytics_jnlp_port = 50000

  # mobile.jenkins.couchbase.com
  mobile_cpu       = 2048
  mobile_memory    = 4096
  mobile_ui_port   = 8080
  mobile_jnlp_port = 50000

  # jenkins workers
  worker_cpu    = 4096
  worker_memory = 7168
}

module "server_jenkins" {
  source  = "./services/jenkins"
  stopped = local.stopped || local.jenkins_stopped || local.server_jenkins_stopped
  lb_stopped = local.lbs_stopped # danger - when you bring it back up it'll have a different fqdn
  prefix  = local.name

  ui_port       = local.server_ui_port
  jnlp_port     = local.server_jnlp_port
  hostname      = "server"
  subdomain     = "jenkins"
  image         = local.jenkins_image
  master_cpu    = local.server_cpu
  master_memory = local.server_memory
  context       = "EC2"

  efs_security_group = aws_security_group.efs
  bastion_security_group = module.bastion.security_group

  domain              = local.domain
  dns_namespace       = aws_service_discovery_private_dns_namespace.main
  worker_cpu          = local.worker_cpu
  worker_memory       = local.worker_memory
  vpc_id              = module.vpc.vpc_id
  ecs_cluster         = aws_ecs_cluster.main
  private_key         = tls_private_key.main
  public_subnets      = module.vpc.public_subnets
  private_subnets     = module.vpc.private_subnets
  ecs_task_runner_arn = aws_iam_policy.ecs_task_runner.arn
  efs_file_system     = aws_efs_file_system.main
  ecs_execution_role  = aws_iam_role.ec2_ecs
  ecs_role            = aws_iam_role.ecs
  profiledata_key     = module.profiledata.key
  region              = local.region

  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks

  images = {
    # tools
    "clamav"         = "284614897128.dkr.ecr.us-east-1.amazonaws.com/clamav-slave:20201216"
    "ansible"        = "284614897128.dkr.ecr.us-east-1.amazonaws.com/ansible-slave:20201218"
    # builders
    "operator-build" = "284614897128.dkr.ecr.us-east-1.amazonaws.com/ubuntu-2004-operator-build:latest"
    "amzn2"          = "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-amzn2-build:20201211"
    "centos7"        = "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-centos7-build:20201214"
    "centos8"        = "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-centos8-build:20201214"
    "debian8"        = "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-debian8-build:20201214"
    "debian8-alice"  = "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-debian8-alice-build:20201215"
    "debian9"        = "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-debian9-build:20201211"
    "debian10"       = "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-debian10-build:20201211"
    "suse15"         = "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-suse15-build:20201211"
    "ubuntu16"       = "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-ubuntu16-build:20201211"
    "ubuntu18"       = "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-ubuntu18-build:20201211"
    "ubuntu20"       = "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-ubuntu20-build:20201211"
  }
}

module "cv_jenkins" {
  source  = "./services/jenkins"
  stopped = local.stopped || local.jenkins_stopped || local.cv_jenkins_stopped
  lb_stopped = local.lbs_stopped # danger - when you bring it back up it'll have a different fqdn
  prefix  = local.name

  ui_port       = local.cv_ui_port
  jnlp_port     = local.cv_jnlp_port
  hostname      = "cv"
  subdomain     = "jenkins"
  image         = local.jenkins_image
  master_cpu    = local.cv_cpu
  master_memory = local.cv_memory
  context       = "EC2"

  efs_security_group = aws_security_group.efs
  bastion_security_group = module.bastion.security_group

  domain              = local.domain
  dns_namespace       = aws_service_discovery_private_dns_namespace.main
  worker_cpu          = local.worker_cpu
  worker_memory       = local.worker_memory
  vpc_id              = module.vpc.vpc_id
  ecs_cluster         = aws_ecs_cluster.main
  private_key         = tls_private_key.main
  public_subnets      = module.vpc.public_subnets
  private_subnets     = module.vpc.private_subnets
  ecs_task_runner_arn = aws_iam_policy.ecs_task_runner.arn
  efs_file_system     = aws_efs_file_system.main
  ecs_execution_role  = aws_iam_role.ec2_ecs
  ecs_role            = aws_iam_role.ecs
  profiledata_key     = module.profiledata.key
  region              = local.region

  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks

  images = {
    "ubuntu18-small" = "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-ubuntu18-cv:20201211"
    "ubuntu18-large" = "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-ubuntu18-cv:20201211"
  }
}

module "analytics_jenkins" {
  source  = "./services/jenkins"
  stopped = local.stopped || local.jenkins_stopped || local.analytics_jenkins_stopped
  lb_stopped = local.lbs_stopped # danger - when you bring it back up it'll have a different fqdn
  prefix  = local.name

  ui_port       = local.analytics_ui_port
  jnlp_port     = local.analytics_jnlp_port
  hostname      = "analytics"
  subdomain     = "jenkins"
  image         = local.jenkins_image
  master_cpu    = local.analytics_cpu
  master_memory = local.analytics_memory
  context       = "EC2"

  efs_security_group = aws_security_group.efs
  bastion_security_group = module.bastion.security_group

  domain              = local.domain
  dns_namespace       = aws_service_discovery_private_dns_namespace.main
  worker_cpu          = local.worker_cpu
  worker_memory       = local.worker_memory
  vpc_id              = module.vpc.vpc_id
  ecs_cluster         = aws_ecs_cluster.main
  private_key         = tls_private_key.main
  public_subnets      = module.vpc.public_subnets
  private_subnets     = module.vpc.private_subnets
  ecs_task_runner_arn = aws_iam_policy.ecs_task_runner.arn
  efs_file_system     = aws_efs_file_system.main
  ecs_execution_role  = aws_iam_role.ec2_ecs
  ecs_role            = aws_iam_role.ecs
  profiledata_key     = module.profiledata.key
  region              = local.region

  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks

  images = {
    "ubuntu18" = "284614897128.dkr.ecr.us-east-1.amazonaws.com/analytics-ubuntu18-cv:latest"
  }
}

module "mobile_jenkins" {
  source  = "./services/jenkins"
  stopped = local.stopped || local.jenkins_stopped || local.mobile_jenkins_stopped
  prefix  = local.name
  lb_stopped = local.lbs_stopped # danger - when you bring it back up it'll have a different fqdn

  ui_port       = local.mobile_ui_port
  jnlp_port     = local.mobile_jnlp_port
  hostname      = "mobile"
  subdomain     = "jenkins"
  image         = local.jenkins_image
  master_cpu    = local.mobile_cpu
  master_memory = local.mobile_memory
  context       = "EC2"

  efs_security_group = aws_security_group.efs
  bastion_security_group = module.bastion.security_group

  domain              = local.domain
  dns_namespace       = aws_service_discovery_private_dns_namespace.main
  worker_cpu          = local.worker_cpu
  worker_memory       = local.worker_memory
  vpc_id              = module.vpc.vpc_id
  ecs_cluster         = aws_ecs_cluster.main
  private_key         = tls_private_key.main
  public_subnets      = module.vpc.public_subnets
  private_subnets     = module.vpc.private_subnets
  ecs_task_runner_arn = aws_iam_policy.ecs_task_runner.arn
  efs_file_system     = aws_efs_file_system.main
  ecs_execution_role  = aws_iam_role.ec2_ecs
  ecs_role            = aws_iam_role.ecs
  profiledata_key     = module.profiledata.key
  region              = local.region

  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks

  #mobile doesn't need these
  images = {
    #"litecore-centos6"     = "284614897128.dkr.ecr.us-east-1.amazonaws.com/litecore-centos-69-build"
    "litecore-centos6-gcc" = "284614897128.dkr.ecr.us-east-1.amazonaws.com/litecore-centos-69-gcc-build"
    "litecore-centos72"    = "284614897128.dkr.ecr.us-east-1.amazonaws.com/litecore-centos-72-build"
    "litecore-centos73"    = "284614897128.dkr.ecr.us-east-1.amazonaws.com/litecore-centos-73-build"
    "litecore-ubuntu14"    = "284614897128.dkr.ecr.us-east-1.amazonaws.com/litecore-ubuntu-1404-build"
    "sgw-centos6"          = "284614897128.dkr.ecr.us-east-1.amazonaws.com/sgw-centos6-build"
    "sgw-centos7"          = "284614897128.dkr.ecr.us-east-1.amazonaws.com/sgw-centos7-build"
    "sgw-ubuntu16"         = "284614897128.dkr.ecr.us-east-1.amazonaws.com/sgw-ubuntu16-build"
    "liteandroid-ubuntu18" = "284614897128.dkr.ecr.us-east-1.amazonaws.com/liteandroid-ubuntu-1804-build"
  }
}
