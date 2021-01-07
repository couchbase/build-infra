output "_JENKINS_MASTER_URL_analytics" {
  value = module.analytics_jenkins.url
}

output "_JENKINS_MASTER_URL_cv" {
  value = module.cv_jenkins.url
}

output "_JENKINS_MASTER_URL_server" {
  value = module.server_jenkins.url
}

output "bastion_ssh" {
  value = module.bastion.ssh_cmd
}

data "http" "ifconfig" {
  url = "http://ifconfig.io/ip"
}

output "zz_now_add_yourself_to_load_balancer_and_bastion_security_groups" {
  value = "${trim(data.http.ifconfig.body, "\n")}/32"
}

output "_ECS_CLOUD_CONFIG_server_jenkins_ecs_config" {
  value = module.server_jenkins.cloud_config_path
}

output "_ECS_CLOUD_CONFIG_cv_jenkins_ecs_config" {
  value = module.cv_jenkins.cloud_config_path
}

output "_ECS_CLOUD_CONFIG_analytics_jenkins_ecs_config" {
  value = module.analytics_jenkins.cloud_config_path
}
