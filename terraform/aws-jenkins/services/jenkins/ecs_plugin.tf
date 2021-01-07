
resource "local_file" "cloud_config" {
    content = templatefile("${path.module}/files/config/${var.hostname}_clouds.tpl", {
        cloud_name            = var.ecs_cluster.name
        task_prefix           = var.prefix
        cluster_arn           = var.ecs_cluster.arn
        region                = var.region
        jenkins_tunnel        = "${local.fqdn}:${var.jnlp_port}"
        jenkins_url           = "http://${local.fqdn}:8080"
        execution_role        = var.ecs_execution_role.arn
        security_groups       = aws_security_group.jenkins_worker.id
        subnets               = join(",", var.private_subnets)
        cloudwatch_log_group  = aws_cloudwatch_log_group.jenkins_workers.name
        cloudwatch_log_prefix = "worker"
    })
    filename = "/tmp/${var.prefix}-${var.hostname}.cloudconfig"
}
